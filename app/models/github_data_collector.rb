
class GithubBadResponse < RuntimeError
end

class GithubDataCollector
  attr_accessor(:options)

  def initialize(options = {})
    @options = options
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
        request.basic_auth AppConfig.github.user, ENV['GITHUB_PASSWORD']

        response = http.request request # Net::HTTPResponse object
        raise GithubBadResponse.new msg: "Bad response from github #{response.code}", response: response if response.code != '200'

        if response.header['link'].present?
          page_str = response.header['link'].split(',').select {|s| s =~ /\"last\"/}.first
          pages = page_str[/&page=[0-9]+/].scan(/[0-9]+/).first.to_i if page_str
        end

        response_json = JSON.parse(response.body)
        response_json.reject! {|pr| Time.parse(pr[limit_field]) < limit_time} if constraint.count > 0
        response_data << response_json
        page += 1
      end while page < pages
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
      request.basic_auth AppConfig.github.user, ENV['GITHUB_PASSWORD']

      response = http.request request # Net::HTTPResponse object

      raise GithubBadResponse.new msg: "Bad response from github #{response.code}", response: response if response.code != '200'

      Rails.logger.error 'get_repo_list returned paginated response (not supported)' if response.header['link'].present?

      JSON.parse(response.body).map {|repo| repo['full_name']}
    end
  end

  def self.get_prs(_output_path, repo_list, state, options = {})
    require 'thread/pool'

    all_prs = []

    pool = Thread.pool(AppConfig.github_data_collector.thread_pool.size)
    merge_mutex = Mutex.new

    repo_list.each {|repo|
      pool.process {
        begin
          data_collector = new options
          repo_pr_data = data_collector.fetch_pullrequests repo, state, state == 'closed' ?
              { 'closed_at' => (options[:closed_days] || 30).days } : {}
          if repo_pr_data.present?
            merge_mutex.synchronize {
              all_prs = (all_prs << repo_pr_data).flatten
            }
          end
        rescue Exception => e
          Rails.logger.error "#{e.message} #{e.backtrace}"
        end
      }
    }
    pool.shutdown

    all_prs
  end
end
