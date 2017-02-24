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
# every 1.hour do
  runner "GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'rails', state: 'open'"
# end

# Closed PRs
every 1.day, at: '6:00 am' do
  # runner "GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today"
  runner "GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_hour, 'rails'"
  # runner "GithubDataFile.get_user_prs 'archive', GithubDataFile.prefix_today, 'jsor', closed_days: 60"
  # runner "GithubDataFile.get_org_prs 'archive', GithubDataFile.prefix_today, 'enova'"
end
