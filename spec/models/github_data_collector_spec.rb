require 'rails_helper'

RSpec.describe GithubDataCollector do
  context 'repo_list' do
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
end
