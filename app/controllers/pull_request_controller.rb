class PullRequestController < ApplicationController
  require 'hash_arrays'
  skip_before_action :verify_authenticity_token
  VALID_VIEW_TYPES = %w(author_summary repo_summary details).freeze

  def open
    params_to_session

    file = GithubDataFile.most_recent('archive', '*_open_pr_data.json')

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data] : []

    session['view_type'] ||= 'details'

    view_data = if respond_to? "open_#{session['view_type']}_json"
                  send("open_#{session['view_type']}_json", pr_data)
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

    file = GithubDataFile.most_recent('archive', '*_closed_pr_data.json')

    file_data = GithubDataFile.load_files(file)

    pr_data = file_data.present? ? file_data.last[:pr_data].where(state: 'closed') : []

    pr_data = pr_data.where(merged_at: /./) if filter_value?(:unmerged, false) == false

    session['view_type'] ||= 'details'

    view_data = if respond_to? "closed_#{session['view_type']}_json"
                  send("closed_#{session['view_type']}_json", pr_data)
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

  def filter_syms
    [:unmerged, :view_type]
  end

  def params_to_session
    if params[:view_type].present? && !(VALID_VIEW_TYPES.include? params[:view_type])
      params.delete(:view_type)
    end

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

  def open_author_summary_json(pr_data)
    pr_data.sort_by! {|pr| pr[:author].downcase}

    authors = pr_data.map {|pr| pr[:author]}.uniq

    summary_data = authors.map {|author|
      author_prs = pr_data.where(author: author)

      {
        author: author,
        total: author_prs.count,
        repo_count: author_prs.map {|pr| pr[:repo]}.uniq.count,
        open_time: author_prs.map {|pr|
                     ((Time.now - Time.parse(pr[:created_at])).to_i / 3600).to_f
                   }.sum / author_prs.count
      }
    }
  end

  def open_repo_summary_json(pr_data)
    pr_data.sort_by! {|pr| pr[:repo].downcase}

    repos = pr_data.map {|pr| pr[:repo]}.uniq

    summary_data = repos.map {|repo|
      repo_prs = pr_data.where(repo: repo)

      {
        repo: repo,
        total: repo_prs.count,
        authors: repo_prs.map {|pr| pr[:author]}.count,
        open_time: repo_prs.map {|pr|
                     ((Time.now - Time.parse(pr[:created_at])).to_i / 3600).to_f
                   }.sum / repo_prs.count
      }
    }
  end

  def open_details_json(pr_data)
    pr_data.sort_by! {|pr| pr[:repo].downcase}
  end

  def closed_author_summary_json(pr_data)
    pr_data.sort_by! {|pr| pr[:author].downcase}

    authors = pr_data.map {|pr| pr[:author]}.uniq

    summary_data = authors.map {|author|
      author_prs = pr_data.where(author: author)

      {
        author: author,
        total: author_prs.count,
        repo_count: author_prs.map {|pr| pr[:repo]}.uniq.count,
        merge_time: author_prs.map {|pr|
                      (pr[:merged_at].present? ? (Time.parse(pr[:merged_at]) - Time.parse(pr[:created_at])).to_i / 3600 : 0).to_f
                    }.sum / author_prs.count,
        intg_time: author_prs.map {|pr|
                     (pr[:merged_at].present? ? (Time.parse(pr[:closed_at]) - Time.parse(pr[:merged_at])).to_i / 3600 : 0).to_f
                   }.sum / author_prs.count,
        close_time: author_prs.map {|pr|
                      (pr[:merged_at].present? ?
                          (Time.parse(pr[:closed_at]) - Time.parse(pr[:merged_at])).to_i / 3600 :
                          (Time.parse(pr[:closed_at]) - Time.parse(pr[:created_at])).to_i / 3600).to_f
                    }.sum / author_prs.count
      }
    }
  end

  def closed_repo_summary_json(pr_data)
    pr_data.sort_by! {|pr| pr[:repo].downcase}

    repos = pr_data.map {|pr| pr[:repo]}.uniq

    summary_data = repos.map {|repo|
      repo_prs = pr_data.where(repo: repo)

      {
        repo: repo,
        total: repo_prs.count,
        authors: repo_prs.map {|pr| pr[:author]}.count,
        merge_time: repo_prs.map {|pr|
                      (pr[:merged_at].present? ? (Time.parse(pr[:merged_at]) - Time.parse(pr[:created_at])).to_i / 3600 : 0).to_f
                    }.sum / repo_prs.count,
        intg_time: repo_prs.map {|pr|
                     (pr[:merged_at].present? ? (Time.parse(pr[:closed_at]) - Time.parse(pr[:merged_at])).to_i / 3600 : 0).to_f
                   }.sum / repo_prs.count,
        close_time: repo_prs.map {|pr|
                      (pr[:merged_at].present? ?
                          (Time.parse(pr[:closed_at]) - Time.parse(pr[:merged_at])).to_i / 3600 :
                          (Time.parse(pr[:closed_at]) - Time.parse(pr[:created_at])).to_i / 3600).to_f
                    }.sum / repo_prs.count
      }
    }
  end

  def closed_details_json(pr_data)
    pr_data.sort_by! {|pr| pr[:repo].downcase}
  end
end
