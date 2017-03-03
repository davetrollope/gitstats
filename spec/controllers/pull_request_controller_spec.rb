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

    expect(response.code).to eq('200')
  end

  it '#closed includes unmerged data when selected' do
    expect(GithubDataFile).to receive(:most_recent).and_return(['spec/fixtures/user_closed_summary.json'])

    session[:unmerged] = 'unmerged'
    session['view_type'] = 'repo_summary'
    get :closed

    expect(response.code).to eq('200')
  end

  it '#open uses default data when there is no custom method' do
    expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

    get :open

    expect(response.code).to eq('200')
  end

  it '#params_to_session deletes invalid view types and defaults to details' do
    get :open, params: { view_type: :invalid }

    expect(session['view_type']).to eq('details')
    expect(response.code).to eq('200')
  end

  it '#closed filters by number of days' do
    allow(Time).to receive(:now).and_return(Time.parse('2017-01-12T9:21:51Z'))
    expect(GithubDataFile).to receive(:most_recent).and_return(['spec/fixtures/user_closed_summary.json'])

    get :closed, params: { days: 1 }, format: 'json'

    json = JSON.parse(response.body)
    expect(json.count).to eq(1)
  end

  it '#sync_session_project resets the project in the session when not in the project list' do
    session['project'] = 'junk'
    expect(GithubDataFile).to receive(:projects).and_return(['project'])

    get :closed

    expect(session['project']).to eq('project')
  end

  it '#open syncs the session' do
    expect(controller).to receive(:sync_session_project)
    get :open
  end

  it '#closed syncs the session' do
    expect(controller).to receive(:sync_session_project)
    get :closed
  end
end
