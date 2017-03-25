class PullRequestController < ApplicationController
  require 'hash_arrays'
  skip_before_action :verify_authenticity_token

  include ColumnSelectionHelper

  VALID_VIEW_TYPES = %w(author_summary repo_summary details).freeze

  before_action :params_to_session, only: [:open, :closed]

  attr_reader :projects, :repos
  attr_accessor :open_column_defs, :closed_column_defs

  def initialize
    super
    @open_column_defs = ColumnSelection.new OPEN_COLUMN_DEFS, 'total', 'repo_summary'
    @closed_column_defs = ColumnSelection.new CLOSED_COLUMN_DEFS, 'total', 'repo_summary'
  end

  def open
    if session[:trend]
      trend 'open', :created_at
    else
      current 'open', :created_at
    end
  end

  def closed
    current('closed', :closed_at) {|pr_data|
      include_only_merged_prs pr_data
    }
  end

  def filter_syms
    [:unmerged, :view_type, :project, :trend]
  end

  def numeric_filter_syms
    [:days]
  end

  def boolean_syms
    [:unmerged, :trend]
  end

  def params_to_session
    if params[:view_type].present? && !(VALID_VIEW_TYPES.include? params[:view_type])
      params.delete(:view_type)
    end

    boolean_syms.each {|sym|
      params.delete(sym) if params[sym].present? && params[sym] == 'false'
    }

    [filter_syms, numeric_filter_syms].flatten.each {|sym|
      session[sym.to_s] = params[sym] if params[sym].present?
    }
  end

  def current_settings
    # intersecting with session.keys ensures we only return things in the session
    # and don't try and access settings that aren't there. Subtle, but safe - handles nil values
    (session.keys & [filter_syms, numeric_filter_syms].flatten.map(&:to_s)).map {|k|
      [k.to_sym, session[k.to_sym]]
    }.to_h
  end

  def view_type
    session['view_type']
  end

  def set_filters
    filter_syms.each {|sym|
      session[sym.to_s] = params[sym] if params[sym].present?
      session[sym.to_s] = false unless session[sym.to_s].present?
    }
    numeric_filter_syms.each {|sym|
      session[sym.to_s] = params[sym] if params[sym].present?
      session[sym.to_s] = 0 unless session[sym.to_s].present?
    }

    sync_session_repos

    if params[:commit].present?
      # There is a bug here. Since unmerged is a closed only filter,
      # it gets deleted when editing open filters - look at referrer?
      session.delete 'unmerged' if params[:unmerged].nil?

      session.delete 'trend' if params[:trend].nil?
    end

    redirect_to request.referer.nil? ? root_path : "#{request.referer.split('?')[0]}?#{current_settings.to_query}"
  end

  def filter_value?(sym, default_value = true)
    session.include?(sym.to_s) ? session[sym.to_s] : default_value
  end

  private

  def current(state, primary_field)
    pattern = "*_#{state}_pr_data.json"
    build_project_list pattern

    file_data = GithubDataFile.load_most_recent_file 'archive', pattern, session['project']
    pr_data = file_data.present? ? file_data.last[:pr_data].where(state: state) : []
    @file = file_data.present? ? file_data.last[:filename] : ''

    @start_time = earliest_data pr_data
    pr_data = reduce_by_time pr_data, primary_field

    pr_data = yield(pr_data) if block_given?

    build_repo_list pr_data

    pr_data = reduce_to_current_repos pr_data

    session['view_type'] ||= 'repo_summary'

    view_data = customize_data pr_data, "#{state}_#{session['view_type']}_json"
    respond_to do |format|
      format.html {
        if view_data.count > 0
          render "_#{state}_#{session['view_type']}", locals: { pr_data: view_data }
        else
          render '_no_data'
        end
      }
      format.json {
        render json: view_data
      }
    end
  end

  def trend(state, primary_field)
    pattern = "*_#{state}_pr_data.json"
    build_project_list pattern

    if view_type == 'details'
      pr_data = GithubDataFile.load_unique_data 'archive', pattern, session['project']

      view_data = [{ pr_data: pr_data }]
    else
      view_data = GithubDataFile.load_files 'archive', pattern, session['project'] {|f, json|
        start_time = earliest_data json[:pr_data]
        @start_time = start_time if @start_time.nil? || start_time < @start_time

        json[:pr_data] = reduce_by_time json[:pr_data], primary_field

        customize_load f, json, "#{state}_#{session['view_type']}_trend_json"
      }
    end
    @file = ''

    repos = []
    view_data.each {|file_hash|
      repos << build_repo_list(file_hash[:pr_data])
      file_hash[:pr_data] = reduce_to_current_repos file_hash[:pr_data]
    }
    @repos = repos.flatten.uniq

    session['view_type'] ||= 'repo_summary'

    respond_to do |format|
      format.html {
        if view_data.count > 0
          render "_#{state}_#{session['view_type']}_trend", locals: { file_data: view_data }
        else
          render '_no_data'
        end
      }
      format.json {
        render json: view_data
      }
    end
  end

  def build_project_list(pattern)
    @projects = GithubDataFile.projects('archive', pattern)
    session['project'] = @projects.first unless session['project'].present? && @projects.include?(session['project'])
    @projects
  end

  def build_repo_list(pr_data)
    @repos = pr_data.map {|pr| pr[:repo]}.uniq
  end

  def sync_session_repos
    repo_field = "#{session['project']}_repos"
    if params[repo_field].present?
      session[repo_field] = params[repo_field]
    elsif params[:commit].present?
      # Only the dropdown menu apply button should cause the repo field to be cleared.
      session.delete repo_field
    end
  end

  def earliest_data(pr_data)
    pr_data.present? ? Time.parse(pr_data.map {|hash| hash[:created_at]}.sort.first) : nil
  end

  def reduce_by_time(pr_data, field)
    days = filter_value?(:days, 0).to_i
    if days > 0
      limit_time = Time.now - days.days
      pr_data = pr_data.select {|hash| hash[field] > limit_time }
    end
    pr_data
  end

  def include_only_merged_prs(pr_data)
    filter_value?(:unmerged, false) == false ? pr_data.where(merged_at: /./) : pr_data
  end

  def reduce_to_current_repos(pr_data)
    project_repo_field = "#{session['project']}_repos"

    session[project_repo_field].present? ? pr_data.select {|hash| session[project_repo_field].include? hash[:repo]} : pr_data
  end

  def customize_data(pr_data, name)
    if PrViewDataMappingHelper.respond_to? name
      PrViewDataMappingHelper.send(name, pr_data)
    else
      pr_data
    end
  end

  def customize_load(f, json, name)
    if PrViewDataMappingHelper.respond_to? name
      PrViewDataMappingHelper.send(name, f, json)
    else
      json
    end
  end
end
