require 'github_data_collector'

class GithubDataFile
  def self.expand_prefix(prefix, name, state)
    "#{prefix}_#{name}_#{state}"
  end

  def self.get_user_prs(output_path, prefix, username = nil, options = {})
    user_repos = GithubDataCollector.get_repo_list username.nil? ? 'user/repos' : "users/#{username}/repos"

    state = options[:state] || 'closed'

    aggregated_pr_data = GithubDataCollector.get_prs output_path, user_repos, state, options

    new.export(output_path, expand_prefix(prefix, username || GithubDataCollector.username, state), aggregated_pr_data)
  end

  def self.get_org_prs(output_path, prefix, orgname, options = {})
    user_repos = GithubDataCollector.get_repo_list "orgs/#{orgname}/repos"

    state = options[:state] || 'closed'

    aggregated_pr_data = GithubDataCollector.get_prs output_path, user_repos, state, options

    new.export(output_path, expand_prefix(prefix, orgname, state), aggregated_pr_data)
  end

  def self.get_consolidated_user_prs(output_path, pattern, prefix, username = nil, options = {})
    get_user_prs(output_path, prefix, username, options) if options[:skip_fetch].nil?

    state = options[:state] || 'closed'

    username ||= GithubDataCollector.username
    expanded_prefix = expand_prefix(prefix, username, state)

    files = file_set(output_path, pattern, username)

    reduce_files_by_time("#{output_path}/#{expanded_prefix}_consolidated_pr_data.json", files, prefix, [:repo, :author]) {|f, json|
      GithubDataFile.customize_load f, json, "#{state}_consolidated_json"
    }
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

    def reduce_files_by_time(output_file, files, filedate, primary_keys)
      files.select {|file| file_date(file) == filedate}

      alljson = files.map {|file|
        file_hash = load_file(file)

        file_hash[:pr_data] = yield(file, file_hash[:pr_data]) if block_given?

        file_hash
      }

      alljson = reduce_json_files_by_time alljson, primary_keys

      File.write(output_file, JSON.pretty_generate(alljson))
    end

    def reduce_json_files_by_time(json_data, view_fields)
      dates = json_data.map {|file_hash| file_hash[:file_date] && file_hash[:file_date].sub(/_.*/, '') }.uniq
      if dates.count < json_data.count
        new_data = []

        dates.each {|date|
          r = Regexp.new "^#{date}"
          day_data = json_data.select {|file_hash| file_hash[:file_date] =~ r }

          dated_pr_data = []
          dated_file_hash = { file_date: date, pr_data: dated_pr_data }
          new_data << dated_file_hash

          view_fields.each {|view_field|
            primary_data = day_data.map {|file_hash|
              file_hash[:pr_data].select {|summary| summary[view_field].present? }.map {|summary|
                summary[view_field]
              }
            }.flatten.uniq
            primary_data.each {|primary_value|
              aggregate_day(dated_pr_data, day_data, view_field, primary_value)
            }
          }
        }
        json_data = new_data
      end

      json_data
    end

    def aggregate_day(dated_pr_data, day_data, view_field, value)
      repo_pr_data = dated_pr_data.find { |pr_summary| pr_summary[view_field] == value }
      if repo_pr_data.nil?
        repo_pr_data = { view_field => value, count: 0 }
        dated_pr_data << repo_pr_data
      end

      day_data.each { |file_hash|
        repo_day_data = file_hash[:pr_data].select { |summary| summary[view_field] == value }
        repo_pr_data[:count] += repo_day_data.count
        repo_pr_data[view_field] = value

        next unless repo_day_data.present?
        repo_day_data.first.keys.each { |key|
          next unless [:repo, :author, :created_at, :merged_at, :closed_at].exclude? key

          day_total = repo_day_data.pluck(key).compact.sum
          if repo_pr_data[key].nil?
            repo_pr_data[key] = day_total
          else
            repo_pr_data[key] += day_total
          end
        }
      }

      # Now divide totals to get average
      repo_pr_data.keys.each { |key|
        if [:repo, :author, :count].exclude? key
          repo_pr_data[key] = repo_pr_data[key].to_f / repo_pr_data[:count]
        end

        repo_pr_data[:total] = repo_pr_data[:count] / day_data.count
      }
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

    def file_date(file)
      file.scan(/[0-9_]*[0-9]/)[0]
    end

    def load_file(file)
      json_data = JSON.parse(File.read(file))
      json_data.each(&:symbolize_keys!)
      { filename: file, pr_data: json_data, file_date: file_date(file) }
    end

    def load_most_recent_file(path, pattern, project)
      filename = GithubDataFile.most_recent(path, pattern, project)
      return [] if filename.nil?

      file_hash = GithubDataFile.load_file(filename)
      file_hash = yield(filename, file_hash) if block_given?
      [ file_hash ]
    end

    def load_files(path, pattern, project)
      files = file_set(path, pattern, project)
      files.map {|filename|
        file_hash = load_file(filename)
        file_hash = yield(filename, file_hash) if block_given?
        file_hash
      }
    end

    def customize_load(f, json, name)
      if PrViewDataMappingHelper.respond_to? name
        PrViewDataMappingHelper.send(name, f, json)
      else
        json
      end
    end
  end
end
