module PrViewDataMappingHelper
  class << self
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

    def merged_time(pr)
      (Time.parse(pr[:merged_at]) - Time.parse(pr[:created_at])).to_i / 3600
    end

    def integration_time(pr)
      (Time.parse(pr[:closed_at]) - Time.parse(pr[:merged_at])).to_i / 3600
    end

    def closed_time(pr)
      (Time.parse(pr[:closed_at]) - Time.parse(pr[:created_at])).to_i / 3600
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

    def closed_details_json(pr_data)
      pr_data.sort_by! {|pr| pr[:repo].downcase}
    end
  end
end
