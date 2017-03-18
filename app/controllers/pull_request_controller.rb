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
    current 'open', :created_at
  end

  def closed
    current('closed', :closed_at) {|pr_data|
      include_only_merged_prs pr_data
    }
  end

  def filter_syms
    [:unmerged, :view_type, :project]
  end

  def numeric_filter_syms
    [:days]
  end

  def params_to_session
    if params[:view_type].present? && !(VALID_VIEW_TYPES.include? params[:view_type])
      params.delete(:view_type)
    end

    if params[:unmerged].present? && params[:unmerged] == 'false'
      params.delete(:unmerged)
    end

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
      session.delete 'unmerged' if params[:unmerged].nil?
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

    files, file_data = load_most_recent_file pattern
    pr_data = file_data.present? ? file_data.last[:pr_data].where(state: state) : []
    @file = files.count > 0 ? files.first : ''

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

  def load_most_recent_file(pattern)
    file = GithubDataFile.most_recent('archive', pattern, session['project'])
    file_data = GithubDataFile.load_files(file)
    [file, file_data]
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
end
