require 'rails_helper'

RSpec.describe 'main endpoints' do
  it 'home page' do
    get root_path
    expect(response).to redirect_to(pull_request_open_path)
  end

  ['', '.json'].each {|extension|
    it "open pull requests #{extension}" do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_open_summary.json')

      get "#{pull_request_open_path}#{extension}"
      expect(response.code).to eq('200')
    end

    it "closed pull requests #{extension}" do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      get "#{pull_request_closed_path}#{extension}"
      expect(response.code).to eq('200')
    end

    it "open pull requests #{extension} for 3 days" do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_open_summary.json')

      get "#{pull_request_open_path}#{extension}?days=3"
      expect(response.code).to eq('200')
    end

    it "closed pull requests #{extension} for 3 days" do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      get "#{pull_request_closed_path}#{extension}?days=3"
      expect(response.code).to eq('200')
    end

    [:author_summary, :repo_summary, :details].each {|view_type|
      it "open pull requests, view type #{view_type} #{extension}" do
        expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_open_summary.json')

        get "#{pull_request_open_path}#{extension}?view_type=#{view_type}"
        expect(response.code).to eq('200')
      end

      it 'closed pull requests #{view_type} #{extension}' do
        expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

        get "#{pull_request_closed_path}#{extension}?view_type=#{view_type}"
        expect(response.code).to eq('200')
      end

      it "open pull requests, view type #{view_type} #{extension} trend" do
        expect(GithubDataFile).to receive(:file_set).and_return(['spec/fixtures/user_open_summary.json'])

        get "#{pull_request_open_path}#{extension}?view_type=#{view_type}",
            params: { trend: 'trend' }
        expect(response.code).to eq('200')
      end
    }
  }
end
