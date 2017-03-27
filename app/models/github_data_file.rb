require 'github_data_collector'

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
    pr_data.select {|pr| repo_pr['url'] == pr['url'] }.map {|pr| yield(pr)}.sum
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
        comment_count: pr_field_sum(aggregated_pr_data[:pr_data], pr) {|pullrequest| pullrequest['comments'] },
        mergeable: pr_field_sum(aggregated_pr_data[:pr_data], pr) {|pullrequest| pullrequest['mergeable'] ? 1 : 0 }
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

    def file_set(path, pattern, project = nil)
      files = Dir["#{path}/#{pattern}"].sort_by { |f| File.mtime(f) }
      if project.present?
        project_regex = Regexp.new "[0-9_]*_#{project}"
        files = files.select {|s| s.match project_regex}
      end
      files
    end

    def most_recent(path, pattern, project = nil)
      files = file_set(path, pattern, project)
      files.last
    end

    def load_file(file)
      json_data = JSON.parse(File.read(file))
      json_data.each(&:symbolize_keys!)
      { filename: file, pr_data: json_data, file_date: file.scan(/[0-9_]*[0-9]/)[0] }
    end

    def load_most_recent_file(path, pattern, project)
      file = GithubDataFile.most_recent(path, pattern, project)
      file_data = GithubDataFile.load_file(file)
      [ file_data ]
    end

    def load_files(path, pattern, project)
      files = file_set(path, pattern, project)
      files.map {|filename|
        file_hash = load_file(filename)
        file_hash = yield(filename, file_hash) if block_given?
        file_hash
      }
    end

    def load_unique_data(path, pattern, project)
      files = file_set(path, pattern, project)

      pr_data = {}

      files.each {|file|
        file_hash = load_file(file)

        file_hash[:pr_data].each {|pr|
          id = "#{pr[:repo]}/#{pr[:id]}"
          pr_data[id] = pr
          pr_data[id][:file_date] = file_hash[:file_date]
        }
      }

      pr_data.values
    end
  end
end
