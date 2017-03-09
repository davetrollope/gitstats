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

    let(:open_pr_data) { File.read(Rails.root.join('spec', 'fixtures', 'user_open.json')) }
    let(:closed_pr_data) { update_closed_time(File.read(Rails.root.join('spec', 'fixtures', 'user_closed.json'))) }

    def stub_comments(pr_data_file)
      pr_data = JSON.parse(pr_data_file)

      pr_data.each {|pr|
        stub_request(:get, "#{pr['review_comments_url']}?page=1&per_page=100")
          .to_return(status: 200, body: [].to_json, headers: {})
      }
    end

    it 'gets open prs' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=open')
        .to_return(status: 200, body: open_pr_data, headers: {})

      stub_comments(open_pr_data)

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'open')
      expect(aggregated_pr_data[:prs].count).to eq(JSON.parse(open_pr_data).count)
      expect(aggregated_pr_data[:comments].count).to eq(0)
    end

    it 'gets closed prs within 30 days' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_data, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'closed')
      expect(aggregated_pr_data[:prs].count).to eq(1)
      expect(aggregated_pr_data[:comments].count).to eq(0)
    end

    it 'gets closed prs within 60 days' do
      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_data, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'closed', closed_days: 60.days)
      expect(aggregated_pr_data[:prs].count).to eq(2)
      expect(aggregated_pr_data[:comments].count).to eq(0)
    end

    it 'propogates exceptions' do
      expect(described_class).to receive_message_chain(:new, :fetch_pullrequests).and_raise(GithubBadResponse.new('test exception'))

      expect { described_class.get_prs('testdir', ['test/repo'], 'open') }.to raise_error(GithubBadResponse)
    end

    it 'handles paginated pr responses' do
      response_header = {
        link: '<https://api.github.com/repositories/3711416/pulls?state=closed&per_page=100&page=1>; rel="next",'\
              ' <https://api.github.com/repositories/3711416/pulls?state=closed&per_page=100&page=2>; rel="last"'
      }

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_data, headers: response_header)

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=2&per_page=100&state=closed')
        .to_return(status: 200, body: closed_pr_data, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'closed')
      expect(aggregated_pr_data[:prs].count).to eq(2)
      expect(aggregated_pr_data[:comments].count).to eq(0)
    end

    let(:open_comment_data) { File.read(Rails.root.join('spec', 'fixtures', 'open_comments.json')) }

    it 'handles paginated comment responses' do
      response_header = {
        link: '<https://api.github.com/repositories/8514/pulls/26703/comments?per_page=100&page=1>; rel="next",'\
            ' <https://api.github.com/repositories/8514/pulls/26703/comments?per_page=100&page=2>; rel="last"'
      }

      stub_request(:get, 'https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=open')
        .to_return(status: 200, body: open_pr_data, headers: {})

      stub_request(:get, 'https://api.github.com/repos/test/actioncable-examples/pulls/26/comments?page=1&per_page=100')
        .to_return(status: 200, body: [].to_json, headers: {})

      stub_request(:get, 'https://api.github.com/repos/test/actioncable-examples/pulls/34/comments?page=1&per_page=100')
        .to_return(status: 200, body: open_comment_data, headers: response_header)

      stub_request(:get, 'https://api.github.com/repos/test/actioncable-examples/pulls/34/comments?page=2&per_page=100')
        .to_return(status: 200, body: open_comment_data, headers: {})

      aggregated_pr_data = described_class.get_prs('testdir', ['test/repo'], 'open')
      expect(aggregated_pr_data[:prs].count).to eq(2)
      expect(aggregated_pr_data[:comments].count).to eq(4)
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
end
