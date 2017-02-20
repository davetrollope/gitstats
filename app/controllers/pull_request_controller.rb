class PullRequestController < ApplicationController
  require 'hash_arrays'

  def open
    file = GithubDataFile.most_recent('archive', '*_open_pr_data.json')

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data] : []

    render locals: { pr_data: pr_data }
  end

  def closed
    file = GithubDataFile.most_recent('archive', '*_closed_pr_data.json')

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data].where(state: 'closed') : []

    pr_data = pr_data.where(merged_at: /./) if filter_enabled?(:unmerged, false) == false

    render locals: { pr_data: pr_data }
  end

  def set_filters
    [:unmerged].each {|sym|
      session[sym.to_s] = params[sym] || false
    }
    redirect_back fallback_location: root_path
  end

  def filter_enabled?(sym, default_value = true)
    session.include?(sym.to_s) ? session[sym.to_s] : default_value
  end
end
