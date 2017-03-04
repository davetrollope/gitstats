class PullRequestController < ApplicationController
  require 'hash_arrays'
  skip_before_action :verify_authenticity_token
  VALID_VIEW_TYPES = %w(author_summary repo_summary details).freeze

  attr_reader :projects

  def open
    params_to_session

    pattern = '*_open_pr_data.json'
    build_project_list pattern
    sync_session_project
    file = GithubDataFile.most_recent('archive', pattern, session['project'])

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data] : []

    @start_time = pr_data.present? ? Time.parse(pr_data.map {|hash| hash[:created_at]}.sort.first) : nil

    days = filter_value?(:days, 0).to_i
    if days > 0
      limit_time = Time.now - days.days
      pr_data = pr_data.select {|hash| hash[:created_at] > limit_time }
    end

    session['view_type'] ||= 'details'

    view_data = if PrViewDataMappingHelper.respond_to? "open_#{session['view_type']}_json"
                  PrViewDataMappingHelper.send("open_#{session['view_type']}_json", pr_data)
                else
                  pr_data
                end

    respond_to do |format|
      format.html {
        render "_open_#{session['view_type']}", locals: { pr_data: view_data }
      }
      format.json {
        render json: view_data
      }
    end
  end

  def closed
    params_to_session

    pattern = '*_closed_pr_data.json'

    build_project_list pattern
    sync_session_project

    file = GithubDataFile.most_recent('archive', pattern, session['project'])

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data].where(state: 'closed') : []

    @start_time = pr_data.present? ? Time.parse(pr_data.map {|hash| hash[:created_at]}.sort.first) : nil

    days = filter_value?(:days, 0).to_i
    if days > 0
      limit_time = Time.now - days.days
      pr_data = pr_data.select {|hash| hash[:closed_at] > limit_time }
    end

    pr_data = pr_data.where(merged_at: /./) if filter_value?(:unmerged, false) == false

    session['view_type'] ||= 'details'

    view_data = if PrViewDataMappingHelper.respond_to? "closed_#{session['view_type']}_json"
                  PrViewDataMappingHelper.send("closed_#{session['view_type']}_json", pr_data)
                else
                  pr_data
                end

    respond_to do |format|
      format.html {
        render "_closed_#{session['view_type']}", locals: { pr_data: view_data }
      }
      format.json {
        render json: view_data
      }
    end
  end

  def build_project_list(pattern)
    @projects = GithubDataFile.projects('archive', pattern)
  end

  def sync_session_project
    session['project'] = @projects.first unless session['project'].present? && @projects.include?(session['project'])
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

    [filter_syms, numeric_filter_syms].flatten.each {|sym|
      session[sym.to_s] = params[sym] if params[sym].present?
    }
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
    redirect_back fallback_location: root_path
  end

  def filter_value?(sym, default_value = true)
    session.include?(sym.to_s) ? session[sym.to_s] : default_value
  end
end
