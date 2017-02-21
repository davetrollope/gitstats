module PullRequestHelper
  def self.github_pr_path(repo, id)
    "#{AppConfig.github.httpserver}/#{repo}/pull/#{id}"
  end

  def self.github_repo_path(repo)
    "#{AppConfig.github.httpserver}/#{repo}"
  end
end
