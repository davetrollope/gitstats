class GithubDataFile
  def self.get_user_prs(output_path, prefix, username = nil, options = {})
    user_repos = GithubDataCollector.get_repo_list username.nil? ? 'user/repos' : "users/#{username}/repos"

    state = options[:state] || 'all'

    prs = GithubDataCollector.get_prs output_path, user_repos, state, options

    new.export(output_path, "#{prefix}_#{state}", prs)
  end

  def self.get_org_prs(output_path, prefix, orgname, options = {})
    user_repos = GithubDataCollector.get_repo_list "orgs/#{orgname}/repos"

    state = options[:state] || 'all'

    prs = GithubDataCollector.get_prs output_path, user_repos, state, options

    new.export(output_path, "#{prefix}_#{state}", prs)
  end

  def persistable_pr_fields(pr_data)
    pr_data.map { |pr|
      {
        repo: pr['base']['repo']['full_name'],
        id: pr['number'],
        created_at: pr['created_at'],
        merged_at: pr['merged_at'],
        closed_at: pr['closed_at'],
        state: pr['state'],
        author: pr['user']['login']
      }
    }
  end

  def export(output_path, prefix, pr_data)
    File.write "#{output_path}/#{prefix}_rawpr_data.json", JSON.pretty_generate(pr_data)
    File.write "#{output_path}/#{prefix}_pr_data.json", JSON.pretty_generate(persistable_pr_fields(pr_data))
  end

  def self.write_pr_data(output_path, prefix, repo, options = {})
    data_collector = new options

    data_collector.export(output_path, prefix, data_collector.fetch_pullrequests(repo))
  rescue GithubBadResponse => e
    Rails.logger.error e.inspect.to_s
  end

  def self.prefix_today
    Time.now.strftime '%Y%m%d'
  end

  def self.prefix_hour
    Time.now.strftime '%Y%m%d_%H'
  end

  def self.prefix_datetime
    Time.now.strftime '%Y%m%d_%H%M%S'
  end

  def self.most_recent(path, pattern)
    files = Dir["#{path}/#{pattern}"].sort_by { |f| File.mtime(f) }
    [files.last]
  end

  def self.load_files(files)
    files.map { |file|
      json_data = JSON.parse(File.read(file))
      json_data.each(&:symbolize_keys!)
      { filename: file, pr_data: json_data }
    }
  end
end
