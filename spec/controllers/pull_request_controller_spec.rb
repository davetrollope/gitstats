require 'rails_helper'

RSpec.describe PullRequestController do
  let(:test_repos) { [ 'test/doctrine-postgis' ] }

  it '#set_filters validates filters are copied to the session' do
    post :set_filters, params: { view_type: 'details', project: 'test', test_repos: test_repos, commit: true }

    expect(session['view_type']).to eq('details')
    expect(session['project']).to eq('test')
    expect(session['test_repos']).to eq(test_repos)
    expect(response).to redirect_to(root_path)
  end

  it '#set_filters clears repo list when deselected' do
    post :set_filters, params: { view_type: 'details', project: 'test', commit: true },
                       session: { 'test_repos' => [ 'different_repo' ] }

    expect(session['view_type']).to eq('details')
    expect(session['project']).to eq('test')
    expect(session['test_repos']).to be_nil
    expect(response).to redirect_to(root_path)
  end

  it '#closed uses default data when there is no custom method' do
    expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

    get :closed

    expect(response.code).to eq('200')
  end

  it '#closed includes unmerged data when selected' do
    expect(GithubDataFile).to receive(:most_recent).and_return(['spec/fixtures/user_closed_summary.json'])

    get :closed, session: { unmerged: 'unmerged', 'view_type' => 'repo_summary' }

    expect(response.code).to eq('200')
  end

  it '#open uses default data when there is no custom method' do
    expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

    get :open

    expect(response.code).to eq('200')
  end

  it '#params_to_session deletes invalid view types and defaults to repo_summary' do
    get :open, params: { view_type: :invalid }

    expect(session['view_type']).to eq('repo_summary')
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
    expect(controller).to receive(:build_project_list)
    get :open
  end

  it '#closed syncs the session' do
    expect(controller).to receive(:build_project_list)
    get :closed
  end

  it '#open filters by repo' do
    allow(Time).to receive(:now).and_return(Time.parse('2017-01-12T9:21:51Z'))
    expect(GithubDataFile).to receive(:projects).and_return(['test'])
    expect(GithubDataFile).to receive(:most_recent).and_return(['spec/fixtures/user_open_summary.json'])

    get :open, session: { 'project' => 'test', 'test_repos' => test_repos }, format: 'json'

    json = JSON.parse(response.body)
    expect(json.count).to eq(1)
  end

  it '#closed filters by repo' do
    allow(Time).to receive(:now).and_return(Time.parse('2017-01-12T9:21:51Z'))
    expect(GithubDataFile).to receive(:projects).and_return(['test'])
    expect(GithubDataFile).to receive(:most_recent).and_return(['spec/fixtures/user_closed_summary.json'])

    get :closed, session: { 'project' => 'test', 'test_repos' => test_repos }, format: 'json'

    json = JSON.parse(response.body)
    expect(json.count).to eq(1)
  end
end
