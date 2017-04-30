require 'hash_arrays'
module PrViewDataMappingHelper
  class << self
    def open_author_summary_json(_filename, pr_data)
      pr_data.sort_by! {|pr| pr[:author].downcase}

      authors = pr_data.map {|pr| pr[:author]}.uniq

      summary_data = authors.map {|author|
        author_prs = pr_data.where(author: author)

        {
          author: author,
          total: author_prs.count,
          repo_count: author_prs.map {|pr| pr[:repo]}.uniq.count,
          open_time: author_prs.map {|pr| open_time(pr).to_f}.sum / author_prs.count,
          comment_count: author_prs.map {|pr| pr[:comment_count] || 0}.sum,
          mergeable: author_prs.map {|pr| pr[:mergeable] || 0}.sum
        }
      }
    end

    def open_repo_summary_json(_filename, pr_data)
      pr_data.sort_by! {|pr| pr[:repo].downcase}

      repos = pr_data.map {|pr| pr[:repo]}.uniq

      summary_data = repos.map {|repo|
        repo_prs = pr_data.where(repo: repo)

        {
          repo: repo,
          total: repo_prs.count,
          authors: repo_prs.map {|pr| pr[:author]}.uniq.count,
          open_time: repo_prs.map {|pr| open_time(pr).to_f}.sum / repo_prs.count,
          comment_count: repo_prs.map {|pr| pr[:comment_count] || 0}.sum,
          mergeable: repo_prs.map {|pr| pr[:mergeable] || 0}.sum
        }
      }
    end

    def open_consolidated_json(filename, pr_data)
      new_pr_data = open_repo_summary_json(filename, pr_data)
      new_pr_data.concat open_author_summary_json(filename, pr_data)
    end

    def open_details_json(_filename, pr_data)
      pr_data.sort_by! {|pr| pr[:repo].downcase}
    end

    def open_time(pr)
      ((pr[:closed_at] || Time.now) - Time.parse(pr[:created_at])).to_i / 3600
    end

    def merged_time(pr)
      (Time.parse(pr[:merged_at]) - Time.parse(pr[:created_at])).to_i / 3600
    end

    def integration_time(pr)
      (Time.parse(pr[:closed_at]) - Time.parse(pr[:merged_at])).to_i / 3600
    end

    def closed_time(pr)
      (Time.parse(pr[:closed_at]) - Time.parse(pr[:created_at])).to_i / 3600
    end

    def closed_author_summary_json(_filename, pr_data)
      pr_data.sort_by! {|pr| pr[:author].downcase}

      authors = pr_data.map {|pr| pr[:author]}.uniq

      summary_data = authors.map {|author|
        author_prs = pr_data.where(author: author)

        {
          author: author,
          total: author_prs.count,
          repo_count: author_prs.map {|pr| pr[:repo]}.uniq.count,
          merge_time: author_prs.map {|pr|
                        (pr[:merged_at].present? ? merged_time(pr) : 0).to_f
                      }.sum / author_prs.count,
          intg_time: author_prs.map {|pr|
                       (pr[:merged_at].present? ? integration_time(pr) : 0).to_f
                     }.sum / author_prs.count,
          close_time: author_prs.map {|pr|
                        (pr[:merged_at].present? ? integration_time(pr) : closed_time(pr)).to_f
                      }.sum / author_prs.count
        }
      }
    end

    def closed_repo_summary_json(_filename, pr_data)
      pr_data.sort_by! {|pr| pr[:repo].downcase}

      repos = pr_data.map {|pr| pr[:repo]}.uniq

      summary_data = repos.map {|repo|
        repo_prs = pr_data.where(repo: repo)

        {
          repo: repo,
          total: repo_prs.count,
          authors: repo_prs.map {|pr| pr[:author]}.uniq.count,
          merge_time: repo_prs.map {|pr|
                        (pr[:merged_at].present? ? merged_time(pr) : 0).to_f
                      }.sum / repo_prs.count,
          intg_time: repo_prs.map {|pr|
                       (pr[:merged_at].present? ? integration_time(pr) : 0).to_f
                     }.sum / repo_prs.count,
          close_time: repo_prs.map {|pr|
                        (pr[:merged_at].present? ? integration_time(pr) : closed_time(pr)).to_f
                      }.sum / repo_prs.count
        }
      }
    end

    def closed_details_json(_filename, pr_data)
      pr_data.sort_by! {|pr| pr[:repo].downcase}
    end
  end
end
