require 'rails_helper'

RSpec.describe 'main endpoints' do
  it 'home page' do
    get root_path
    expect(response).to redirect_to(pull_request_open_path)
  end

  ['', '.json'].each {|extension|
    context 'open' do
      before(:each) do
        expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/20170101_user_open_summary.json')
      end

      it "pull requests #{extension}" do
        get "#{pull_request_open_path}#{extension}"
        expect(response.code).to eq('200')
      end

      it "pull requests #{extension} for 3 days" do
        get "#{pull_request_open_path}#{extension}?days=3"
        expect(response.code).to eq('200')
      end

      [:author_summary, :repo_summary, :details].each {|view_type|
        it "pull requests, view type #{view_type} #{extension}" do
          get "#{pull_request_open_path}#{extension}?view_type=#{view_type}"
          expect(response.code).to eq('200')
        end
      }
    end

    context 'open trend' do
      before(:each) do
        expect(GithubDataFile).to receive(:file_set).and_return(['spec/fixtures/20170101_user_open_summary.json',
                                                                 'spec/fixtures/20170102_user_open_summary.json'])
      end

      [:author_summary, :repo_summary, :details].each {|view_type|
        it "pull requests, view type #{view_type} #{extension} trend" do
          get "#{pull_request_open_path}#{extension}?view_type=#{view_type}", params: { trend: 'trend' }
          expect(response.code).to eq('200')
        end
      }
    end

    context 'closed' do
      before(:each) do
        expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')
      end

      it "pull requests #{extension}" do
        get "#{pull_request_closed_path}#{extension}"
        expect(response.code).to eq('200')
      end

      it "pull requests #{extension} for 3 days" do
        get "#{pull_request_closed_path}#{extension}?days=3"
        expect(response.code).to eq('200')
      end

      [:author_summary, :repo_summary, :details].each {|view_type|
        it 'pull requests #{view_type} #{extension}' do
          get "#{pull_request_closed_path}#{extension}?view_type=#{view_type}"
          expect(response.code).to eq('200')
        end
      }
    end
  }
end
