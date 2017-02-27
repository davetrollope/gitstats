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

    it 'gets open prs' do
      stub_request(:get, "https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=open").
          to_return(:status => 200, :body => open_pr_data, :headers => {})

      expect(described_class.get_prs('testdir', ['test/repo'], 'open').count).to eq(JSON.parse(open_pr_data).count)
    end

    it 'gets closed prs within 30 days' do
      stub_request(:get, "https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed").
          to_return(:status => 200, :body => closed_pr_data, :headers => {})

      expect(described_class.get_prs('testdir', ['test/repo'], 'closed').count).to eq(1)
    end

    it 'gets closed prs within 60 days' do
      stub_request(:get, "https://api.github.com/repos/test/repo/pulls?page=1&per_page=100&state=closed").
          to_return(:status => 200, :body => closed_pr_data, :headers => {})

      expect(described_class.get_prs('testdir', ['test/repo'], 'closed', closed_days: 60.days).count).to eq(2)
    end

    it 'propogates exceptions' do
      allow(described_class).to receive_message_chain(:new,:fetch_pullrequests).and_raise(GithubBadResponse.new("test exception"))

      expect { described_class.get_prs('testdir', ['test/repo'], 'open') }.to raise_error(GithubBadResponse)
    end
  end

end
