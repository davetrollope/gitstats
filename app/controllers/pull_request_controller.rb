class PullRequestController < ApplicationController
  require 'hash_arrays'

  def open
    params_to_session

    file = GithubDataFile.most_recent('archive', '*_open_pr_data.json')

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data] : []

    render "_open_#{session['view_type']}", locals: { pr_data: pr_data }
  end

  def closed
    params_to_session

    file = GithubDataFile.most_recent('archive', '*_closed_pr_data.json')

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data].where(state: 'closed') : []

    pr_data = pr_data.where(merged_at: /./) if filter_value?(:unmerged, false) == false

    render "_closed_#{session['view_type']}", locals: { pr_data: pr_data }
  end

  def filter_syms
    [:unmerged, :view_type]
  end

  def params_to_session
    filter_syms.each {|sym|
      session[sym.to_s] = params[sym] if params[sym].present?
    }
  end

  def set_filters
    filter_syms.each {|sym|
      session[sym.to_s] = params[sym] || false
    }
    redirect_back fallback_location: root_path
  end

  def filter_value?(sym, default_value = true)
    session.include?(sym.to_s) ? session[sym.to_s] : default_value
  end
end
