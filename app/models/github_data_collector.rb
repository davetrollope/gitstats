
class GithubBadResponse < StandardError
end

class GithubDataCollector
  attr_accessor(:options)

  def initialize(options = {})
    @options = options
  end

  def self.username
    AppConfig.github.user
  end

  def fetch_pullrequests(repo, state, constraint = {})
    state = 'all' if state.nil?

    require 'net/http'

    uri = URI("#{AppConfig.github.server}/repos/#{repo}/pulls")

    response_data = []
    page = 0
    pages = 1

    if constraint.count > 0
      limit_field = constraint.first[0]
      limit_time = Time.now - constraint.first[1]
    end

    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      begin
        uri = URI("#{AppConfig.github.server}/repos/#{repo}/pulls?state=#{state}&per_page=100&page=#{page + 1}")

        Rails.logger.debug "Getting #{uri.inspect}"

        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth GithubDataCollector.username, ENV['GITHUB_PASSWORD']

        response = http.request request # Net::HTTPResponse object
        raise GithubBadResponse.new msg: "Bad response from github #{response.code}", response: response if response.code != '200'

        GithubDataCollector.log_rate_limits response.header
        if response.header['link'].present?
          page_str = response.header['link'].split(',').select {|s| s =~ /\"last\"/}.first
          pages = page_str[/[?&]page=[0-9]+/].scan(/[0-9]+/).first.to_i if page_str
        end

        response_json = JSON.parse(response.body)
        response_json.reject! {|pr| Time.parse(pr[limit_field]) < limit_time} if constraint.count > 0
        response_data << response_json
        page += 1
      end while page < pages # rubocop:disable Lint/Loop - using a loop increases branch complexity
    end

    response_data.flatten!
  end

  def fetch_pr_comments(repo, pr_data)
    state = 'all' if state.nil?

    require 'net/http'

    uri = URI("#{AppConfig.github.server}/repos/#{repo}/pulls")

    response_data = []

    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      pr_data.each {|pr|
        page = 0
        pages = 1

        begin
          uri = URI("#{pr['review_comments_url']}?per_page=100&page=#{page + 1}")

          Rails.logger.debug "Getting #{uri.inspect}"

          request = Net::HTTP::Get.new uri.request_uri
          request.basic_auth GithubDataCollector.username, ENV['GITHUB_PASSWORD']

          response = http.request request # Net::HTTPResponse object
          raise GithubBadResponse.new msg: "Bad response from github #{response.code}", response: response if response.code != '200'

          GithubDataCollector.log_rate_limits response.header
          if response.header['link'].present?
            page_str = response.header['link'].split(',').select {|s| s =~ /\"last\"/}.first
            pages = page_str[/[?&]page=[0-9]+/].scan(/[0-9]+/).first.to_i if page_str
          end

          response_data << JSON.parse(response.body)
          page += 1
        end while page < pages # rubocop:disable Lint/Loop - using a loop increases branch complexity
      }
    end

    response_data.flatten!
  end

  def self.get_repo_list(uri = 'user/repos')
    require 'net/http'

    uri = URI("#{AppConfig.github.server}/#{uri}?per_page=100")

    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Get.new uri.request_uri
      request.basic_auth GithubDataCollector.username, ENV['GITHUB_PASSWORD']

      response = http.request request # Net::HTTPResponse object

      raise GithubBadResponse.new msg: "Bad response from github #{response.code}", response: response if response.code != '200'

      log_rate_limits(response.header)

      Rails.logger.error 'get_repo_list returned paginated response (not supported)' if response.header['link'].present?

      JSON.parse(response.body).map {|repo| repo['full_name']}
    end
  end

  def self.get_prs(_output_path, repo_list, state, options = {})
    require 'thread/pool'

    all_prs = []
    all_comments = []
    exceptions = []

    pool = Thread.pool(AppConfig.github_data_collector.thread_pool.size)
    merge_mutex = Mutex.new
    exception_mutex = Mutex.new

    repo_list.each {|repo|
      pool.process {
        begin
          data_collector = new options
          repo_pr_data = data_collector.fetch_pullrequests(
            repo, state, state == 'closed' ? { 'closed_at' => (options[:closed_days] || 30).days } : {}
          )

          if repo_pr_data.present?
            repo_comment_data = data_collector.fetch_pr_comments repo, repo_pr_data if state == 'open'

            merge_mutex.synchronize {
              all_prs = (all_prs << repo_pr_data).flatten
              all_comments = (all_comments << repo_comment_data).flatten if repo_comment_data.present?
            }
          end
        rescue StandardError, WebMock::NetConnectNotAllowedError => e
          Rails.logger.error "#{e.message} #{e.backtrace}"
          exception_mutex.synchronize {
            exceptions << e
          }
        end
      }
    }
    pool.shutdown

    exceptions.each {|e| raise e }
    { prs: all_prs, comments: all_comments }
  end

  def self.log_rate_limits(header)
    limit = header['X-RateLimit-Limit']
    remaining = header['X-RateLimit-Remaining'].to_i
    reset_time = header['X-RateLimit-Reset']

    if remaining.zero?
      Rails.logger.warn "RATE LIMITS #{limit}/#{remaining}/#{reset_time}"
    elsif (remaining % 100).zero?
      Rails.logger.info "RATE LIMITS #{limit}/#{remaining}/#{reset_time}"
    end
  end
end
