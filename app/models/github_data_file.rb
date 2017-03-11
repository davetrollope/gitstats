class GithubDataFile
  def self.get_user_prs(output_path, prefix, username = nil, options = {})
    user_repos = GithubDataCollector.get_repo_list username.nil? ? 'user/repos' : "users/#{username}/repos"

    state = options[:state] || 'closed'

    aggregated_pr_data = GithubDataCollector.get_prs output_path, user_repos, state, options

    new.export(output_path, "#{prefix}_#{username || GithubDataCollector.username}_#{state}", aggregated_pr_data)
  end

  def self.get_org_prs(output_path, prefix, orgname, options = {})
    user_repos = GithubDataCollector.get_repo_list "orgs/#{orgname}/repos"

    state = options[:state] || 'closed'

    aggregated_pr_data = GithubDataCollector.get_prs output_path, user_repos, state, options

    new.export(output_path, "#{prefix}_#{orgname}_#{state}", aggregated_pr_data)
  end

  def pr_field_sum(pr_data, repo_pr)
    pr_data.select {|pr|
      repo_pr['url'] == pr['url']
    }.map {|pr| yield(pr)}.sum
  end

  def persistable_pr_fields(aggregated_pr_data)
    aggregated_pr_data[:repo_prs].map { |pr|
      {
        repo: pr['base']['repo']['full_name'],
        id: pr['number'],
        created_at: pr['created_at'],
        merged_at: pr['merged_at'],
        closed_at: pr['closed_at'],
        state: pr['state'],
        author: pr['user']['login'],
        comment_count: pr_field_sum(aggregated_pr_data[:pr_data], pr) {|pr| pr['comments'] },
        mergeable: pr_field_sum(aggregated_pr_data[:pr_data], pr) {|pr| pr['mergeable'] ? 1 : 0 }
      }
    }
  end

  def export(output_path, prefix, aggregated_pr_data)
    File.write "#{output_path}/#{prefix}_rawpr_data.json", JSON.pretty_generate(aggregated_pr_data[:pr_data])
    File.write "#{output_path}/#{prefix}_rawrepopr_data.json", JSON.pretty_generate(aggregated_pr_data[:repo_prs])
    File.write "#{output_path}/#{prefix}_pr_data.json", JSON.pretty_generate(persistable_pr_fields(aggregated_pr_data))
  end

  class << self
    def prefix_today
      Time.now.strftime '%Y%m%d'
    end

    def prefix_hour
      Time.now.strftime '%Y%m%d_%H'
    end

    def prefix_datetime
      Time.now.strftime '%Y%m%d_%H%M%S'
    end

    def projects(path, pattern)
      files = Dir["#{path}/#{pattern}"].sort_by { |f| File.mtime(f) }
      files.map {|s| s.sub(%r{^.*/}, '').sub(/[0-9_]+/, '').split('_')[0]}.uniq
    end

    def most_recent(path, pattern, project = nil)
      files = Dir["#{path}/#{pattern}"].sort_by { |f| File.mtime(f) }
      if project.present?
        project_regex = Regexp.new "[0-9_]*_#{project}"
        files = files.select {|s| s.match project_regex}
      end
      [files.last].compact
    end

    def load_files(files)
      files.map { |file|
        json_data = JSON.parse(File.read(file))
        json_data.each(&:symbolize_keys!)
        { filename: file, pr_data: json_data }
      }
    end
  end
end
