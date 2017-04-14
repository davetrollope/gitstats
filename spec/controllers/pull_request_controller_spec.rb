require 'rails_helper'

RSpec.describe PullRequestController do
  let(:test_repos) { [ 'test/doctrine-postgis' ] }

  def days_since_test_data
    ((Time.now - Time.parse('1/1/2017')) / 60 / 60 / 24).to_i + 1
  end

  context '#set_filters' do
    it 'validates filters are copied to the session' do
      post :set_filters, params: { view_type: 'details', project: 'test', test_repos: test_repos, commit: true }

      expect(session['view_type']).to eq('details')
      expect(session['project']).to eq('test')
      expect(session['test_repos']).to eq(test_repos)
      expect(response).to redirect_to(root_path)
    end

    it 'clears repo list when deselected' do
      post :set_filters, params: { view_type: 'details', project: 'test', commit: true },
                         session: { 'test_repos' => [ 'different_repo' ] }

      expect(session['view_type']).to eq('details')
      expect(session['project']).to eq('test')
      expect(session['test_repos']).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end

  context '#open' do
    it 'uses default data when there is no custom method' do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/20170101_user_open_summary.json')

      expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

      get :open

      expect(response.code).to eq('200')
    end

    it 'syncs the session' do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/20170101_user_open_summary.json')

      expect(controller).to receive(:build_project_list)
      get :open
    end

    it 'filters by repo' do
      allow(Time).to receive(:now).and_return(Time.parse('2017-01-12T9:21:51Z'))
      expect(GithubDataFile).to receive(:projects).and_return(['test'])
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/20170101_user_open_summary.json')

      get :open, session: { 'days' => days_since_test_data, 'project' => 'test', 'test_repos' => test_repos }, format: 'json'

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
    end
  end

  context '#closed' do
    it 'uses default data when there is no custom method' do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      expect(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)

      get :closed

      expect(response.code).to eq('200')
    end

    it 'includes unmerged data when selected' do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      get :closed, session: { 'days' => days_since_test_data, 'unmerged' => 'unmerged', 'view_type' => 'repo_summary' }

      expect(response.code).to eq('200')
    end

    it 'doesnt include unmerged data when passed "false"' do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      get :closed, params: { 'days' => days_since_test_data, 'unmerged' => 'false', 'view_type' => 'details' }

      expect(response.code).to eq('200')
      expect(session['unmerged']).to be_nil
    end

    it 'syncs the session' do
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      expect(controller).to receive(:build_project_list)
      get :closed
    end

    it 'filters by repo' do
      allow(Time).to receive(:now).and_return(Time.parse('2017-01-12T9:21:51Z'))
      expect(GithubDataFile).to receive(:projects).and_return(['test'])
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      get :closed, session: { 'days' => days_since_test_data, 'project' => 'test', 'test_repos' => test_repos }, format: 'json'

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
    end

    it 'filters by number of days' do
      allow(Time).to receive(:now).and_return(Time.parse('2017-01-12T9:21:51Z'))
      expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')

      get :closed, params: { days: 1 }, format: 'json'

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
    end
  end

  it '#set_open_columns replaces the session open columns' do
    session[:open_columns] = 'prcount'

    post :set_open_columns, params: { 'days' => days_since_test_data, 'total' => 'total', 'authors' => 'authors' }

    expect(session[:open_columns]).to eq('total,authors')
    expect(response).to redirect_to(root_path)
  end

  it '#set_closed_columns replaces the session closed columns' do
    session[:closed_columns] = 'prcount,repo_count'

    post :set_closed_columns, params: { 'days' => days_since_test_data, 'total' => 'total', 'authors' => 'authors' }

    expect(session[:closed_columns]).to eq('total,authors,repo_count')
    expect(response).to redirect_to(root_path)
  end

  it '#params_to_session deletes invalid view types and defaults to repo_summary' do
    expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/20170101_user_open_summary.json')

    get :open, params: { view_type: :invalid }

    expect(session['view_type']).to eq('repo_summary')
    expect(response.code).to eq('200')
  end

  it '#sync_session_project resets the project in the session when not in the project list' do
    session['project'] = 'junk'
    expect(GithubDataFile).to receive(:most_recent).and_return('spec/fixtures/user_closed_summary.json')
    expect(GithubDataFile).to receive(:projects).and_return(['project'])

    get :closed

    expect(session['project']).to eq('project')
  end

  it '#customize_load returns original data if no mapping helper' do
    expect(GithubDataFile).to receive(:file_set).and_return(['spec/fixtures/20170101_user_open_summary.json'])

    allow(PrViewDataMappingHelper).to receive(:respond_to?).and_return(false)
    get :open, format: 'json', session: { 'days': days_since_test_data, 'trend': 'trend' }

    expect(response.code).to eq('200')
  end

  [:author_summary, :repo_summary, :details].each {|view_type|
    it "#current handles no files #{view_type}" do
      expect(GithubDataFile).to receive(:most_recent).and_return(nil)

      get :open, session: { 'days' => days_since_test_data, 'view_type': view_type.to_s }

      expect(response.code).to eq('200')
    end
  }

  context 'trend' do
    it 'opens json when there is no data' do
      expect(GithubDataFile).to receive(:load_files).and_return([])
      get :open, session: { 'days': days_since_test_data, 'trend': 'trend' }

      expect(response.code).to eq('200')
    end

    it 'aggregates multiple days data' do
      json_data = JSON.parse(File.read('spec/fixtures/20170101_user_open_summary.json'))
      json_data.each(&:symbolize_keys!)

      json2_data = json_data.clone
      json2_data.delete(json2_data.first)

      expect(GithubDataFile).to receive(:file_set).and_return(
        ['000000_01_open_data.json', '000000_02_open_data.json', '0000001_01_open_data.json']
      )
      expect(GithubDataFile).to receive(:load_file).and_return(
        filename: '000000_01_open_data.json', pr_data: json_data, file_date: '000000'
      )
      expect(GithubDataFile).to receive(:load_file).and_return(
        filename: '000000_02_open_data.json', pr_data: json2_data, file_date: '000000'
      )
      expect(GithubDataFile).to receive(:load_file).and_return(
        filename: '000001_01_open_data.json', pr_data: json2_data, file_date: '000001'
      )

      get :open, session: { 'days': days_since_test_data, 'trend': 'trend' }

      expect(response.code).to eq('200')
    end
  end
end
