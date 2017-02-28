require 'rails_helper'

RSpec.describe PullRequestController do
  it '#set_filters validates filters are copied to the session' do
    post :set_filters, params: { view_type: 'details' }

    expect(session['view_type']).to eq('details')
    expect(response).to redirect_to(root_path)
  end

  it '#closed uses default data when there is no custom method' do
    expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

    get :closed

    expect(response.code).to eq("200")
  end

  it '#closed includes unmerged data when selected' do
    expect(GithubDataFile).to receive(:most_recent).and_return(['spec/fixtures/user_closed_summary.json'])

    session[:unmerged] = 'unmerged'
    session['view_type'] = 'repo_summary'
    get :closed

    expect(response.code).to eq("200")
  end

  it '#open uses default data when there is no custom method' do
    expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

    get :open

    expect(response.code).to eq("200")
  end

  it '#params_to_session deletes invalid view types and defaults to details' do
    get :open, params: { view_type: :invalid }

    expect(session['view_type']).to eq('details')
    expect(response.code).to eq("200")
  end
end
