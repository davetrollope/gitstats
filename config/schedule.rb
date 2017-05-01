# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Some example gitstats jobs

# Open PRs
every :hour, at: 0 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'ruby', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'ruby', state: 'open'"
end

every :hour, at: 5 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'rails', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'rails', state: 'open'"
end

every :hour, at: 10 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'python', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'python', state: 'open'"
end

every :hour, at: 15 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'golang', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'golang', state: 'open'"
end

every :hour, at: 20 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'elixir-lang', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'elixir-lang', state: 'open'"
end

every :hour, at: 25 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'clojure', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, :repo, 'clojure', state: 'open'"
end

every :hour, at: 30 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'jruby', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'jruby', state: 'open'"
end

every :hour, at: 35 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'graalvm', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'graalvm', state: 'open'"
end

every :hour, at: 40 do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'erlang', state: 'open'"
  runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', \"#{GithubDataFile.prefix_today}*_open_pr_data.json\", GithubDataFile.prefix_today, 'erlang', state: 'open'"
end

# Closed PRs
# runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today"
# runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'jsor', closed_days: 60"
# runner "require 'github_data_file'; GithubDataFile.get_org_prs 'archive', GithubDataFile.prefix_today, 'enova'"

every :day, at: '3:02 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'golang'"
end

every :day, at: '4:02 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'elixir-lang'"
end

every :day, at: '4:32 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'erlang'"
end

every :day, at: '5:02 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'ruby'"
end

every :day, at: '5:32 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'jruby'"
end

every :day, at: '6:02 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'rails'"
end

every :day, at: '6:32 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'graalvm'"
end

every :day, at: '7:02 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'python'"
end

every :day, at: '8:02 am' do
  runner "require 'github_data_file'; GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'clojure'"
end
