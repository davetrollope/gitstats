require 'rails_helper'

RSpec.describe GithubDataCollector do
  context '.get_repo_list' do
    let(:expected_repo_list) { ['test/berti', 'test/carty', 'test/dbal', 'test/dbal-sqlite3'] }
    let(:repo_list) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'repo_list.json'))) }

    it 'can retrieve a default list of repos for the user' do
      stub_request(:get, 'https://api.github.com/user/repos?per_page=100')
        .to_return(status: 200, body: repo_list.to_json, headers: {})

      expect(described_class.get_repo_list).to eq(expected_repo_list)
    end

    it 'can retrieve a list of repos for the user' do
      stub_request(:get, 'https://api.github.com/users/tester/repos?per_page=100')
        .to_return(status: 200, body: repo_list.to_json, headers: {})

      expect(described_class.get_repo_list('users/tester/repos')).to eq(expected_repo_list)
    end

    it 'can retrieve a list of repos for an org' do
      stub_request(:get, 'https://api.github.com/orgs/testorg/repos?per_page=100')
        .to_return(status: 200, body: repo_list.to_json, headers: {})

      expect(described_class.get_repo_list('orgs/testorg/repos')).to eq(expected_repo_list)
    end
  end

  context '.get_prs' do
    # Distribute fixture PRs over 25 day intervals from now to allow testing of 30/60 day intervals
    def update_closed_time(pr_data)
      json = JSON.parse(pr_data)
      time = Time.now
      json.each {|pr| time = pr[:closed_at] = time - 25.day}
      json.to_json
    end

    let(:open_pr_list) { File.read(Rails.root.join('spec', 'fixtures', 'user_open.json')) }
    let(:closed_pr_list) { update_closed_time(File.read(Rails.root.join('spec', 'fixtures', 'user_closed.json'))) }

    def stub_comments(pr_data_file)
      pr_data = JSON.parse(pr_data_file)

      pr_data.each {|pr|
        stub_request(:get, (pr['url']).to_s)
          .to_return(status: 200, body: [].to_json, headers: {})
      }
    end

    it 'gets open prs' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=open')
        .to_return(status: 200, body: open_pr_list, headers: {})

      stub_comments(open_pr_list)

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'open')
      expect(aggregated_pr_data[:repo_prs].count).to eq(JSON.parse(open_pr_list).count)
      expect(aggregated_pr_data[:pr_data].count).to eq(0)
    end

    it 'gets closed prs within 30 days' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_list, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'closed')
      expect(aggregated_pr_data[:repo_prs].count).to eq(1)
      expect(aggregated_pr_data[:pr_data].count).to eq(0)
    end

    it 'gets closed prs within 60 days' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_list, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'closed', closed_days: 60.days)
      expect(aggregated_pr_data[:repo_prs].count).to eq(2)
      expect(aggregated_pr_data[:pr_data].count).to eq(0)
    end

    it 'propogates exceptions' do
      expect(described_class).to receive(:github_http_request).and_raise(GithubBadResponse.new('test exception'))

      expect { described_class.get_prs('testdir', ['test/repo'], 'open') }.to raise_error(GithubBadResponse)
    end

    it 'paginated prs propogates exceptions' do
      response_header = {
        link: '<https://api.github.com/repositories/3711416/pulls?state=open&per_page=100&page=1>; rel="next",'\
            ' <https://api.github.com/repositories/3711416/pulls?state=open&per_page=100&page=2>; rel="last"'
      }

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=open')
        .to_return(status: 200, body: open_pr_list, headers: response_header)

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=2&per_page=100&state=open')
        .to_return(status: 403, body: open_pr_list, headers: {})

      expect { described_class.get_prs('testdir', ['test/repo'], 'open') }.to raise_error(GithubBadResponse)
    end

    it 'handles paginated pr responses' do
      response_header = {
        link: '<https://api.github.com/repositories/3711416/pulls?state=closed&per_page=100&page=1>; rel="next",'\
              ' <https://api.github.com/repositories/3711416/pulls?state=closed&per_page=100&page=2>; rel="last"'
      }

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_list, headers: response_header)

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=2&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_list, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'closed')
      expect(aggregated_pr_data[:repo_prs].count).to eq(2)
      expect(aggregated_pr_data[:pr_data].count).to eq(0)
    end

    let(:open_pr_data) { File.read(Rails.root.join('spec', 'fixtures', 'open_pr.json')) }

    it 'open pr gets specific pr data' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=open')
        .to_return(status: 200, body: open_pr_list, headers: {})

      stub_request(:get, 'https://api.github.com/repos/test/actioncable-examples/pulls/26')
        .to_return(status: 200, body: [].to_json, headers: {})

      stub_request(:get, 'https://api.github.com/repos/test/actioncable-examples/pulls/34')
        .to_return(status: 200, body: open_pr_data, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'open')
      expect(aggregated_pr_data[:repo_prs].count).to eq(JSON.parse(open_pr_list).count)
      expect(aggregated_pr_data[:pr_data].count).to eq(2)
    end
  end

  context '#log_rate_limits' do
    it 'generates a warning when rate limits hit 0' do
      header = {
        'X-RateLimit-Limit': 1000,
        'X-RateLimit-Remaining': 0,
        'X-RateLimit-Reset': 9999
      }

      expect(Rails.logger).to receive(:warn)

      described_class.log_rate_limits(header)
    end

    it 'generates a warning log on the 100th request' do
      header = {
        'X-RateLimit-Limit' => '1000',
        'X-RateLimit-Remaining' => '100',
        'X-RateLimit-Reset' => '9999'
      }

      expect(Rails.logger).to receive(:info)

      described_class.log_rate_limits(header)
    end

    it 'does not generate logs for most events' do
      header = {
        'X-RateLimit-Limit' => '1000',
        'X-RateLimit-Remaining' => '99',
        'X-RateLimit-Reset' => '9999'
      }

      expect(Rails.logger).not_to receive(:info)
      expect(Rails.logger).not_to receive(:warn)

      described_class.log_rate_limits(header)
    end
  end

  context '.github_http_request' do
    it 'retries github requests upon receiving 403' do
      uri = URI('http://localhost/repos/1/pulls')

      stub = stub_request(:get, 'http://localhost/repos/1/pulls')
             .to_return(status: 403, body: '', headers: { 'Retry-After' => 2 })

      Net::HTTP.start(uri.host, uri.port) do |http|
        expect { described_class.github_http_request(http, uri) }.to raise_error(GithubBadResponse)
      end

      expect(stub).to have_been_requested.times(3)
    end
  end
end
