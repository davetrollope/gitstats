module PullRequestHelper
  def self.github_pr_path(repo, id)
    "#{AppConfig.github.httpserver}/#{repo}/pull/#{id}"
  end
end
