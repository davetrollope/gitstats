require 'rails_helper'

RSpec.describe 'main endpoints' do
  it 'home page' do
    get root_path
    expect(response).to redirect_to(pull_request_open_path)
  end

  it 'open pull requests' do
    get pull_request_open_path
    expect(response.code).to eq('200')
  end

  it 'closed pull requests' do
    get pull_request_closed_path
    expect(response.code).to eq('200')
  end

  [:author_summary, :repo_summary, :details].each {|view_type|
    it "open pull requests, view type #{view_type}" do
      get "#{pull_request_open_path}?view_type=#{view_type}"
      expect(response.code).to eq('200')
    end

    it 'closed pull requests' do
      get "#{pull_request_closed_path}?view_type=#{view_type}"
      expect(response.code).to eq('200')
    end
  }
end
