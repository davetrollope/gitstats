require 'rails_helper'

RSpec.describe GithubDataFile do
  it '.prefix_today returns a prefix with only the date' do
    expect(Time).to receive(:now).and_return(Time.parse('15/11/2017'))

    expect(described_class.prefix_today).to eq('20171115')
  end

  it '.prefix_hour returns a prefix with the date and the hour' do
    expect(Time).to receive(:now).and_return(Time.parse('15/11/2017 01:02:00'))

    expect(described_class.prefix_hour).to eq('20171115_01')
  end

  it '.prefix_datetime returns a prefix with the date and time' do
    expect(Time).to receive(:now).and_return(Time.parse('15/11/2017 01:02:00'))

    expect(described_class.prefix_datetime).to eq('20171115_010200')
  end

  it '.most_recent returns the most recent file' do
    expect(Dir).to receive(:[]).and_return(%w(a b))
    expect(File).to receive(:mtime).twice.and_return(Time.now)

    expect(described_class.most_recent('archive', '*')).to eq('b')
  end

  it '.file_set with a project returns project files only' do
    expect(Dir).to receive(:[]).and_return(%w(1_prj 2_a))
    expect(File).to receive(:mtime).twice.and_return(Time.now)
    expect(described_class.file_set('dir', '*', 'prj')).to eq(['1_prj'])
  end

  context 'closed pull requests' do
    let(:pr_data) { { repo_prs: JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'user_closed.json'))), pr_data: [] } }

    it '.get_user_prs gets a set of closed pull requests for a user' do
      expect(File).to receive(:write).with('test/prefix_tester_closed_rawpr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_tester_closed_rawrepopr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_tester_closed_pr_data.json', any_args).and_return(nil)
      expect(GithubDataCollector).to receive(:get_repo_list).with('users/tester/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_user_prs('test', 'prefix', 'tester')
    end

    it '.get_user_prs gets all closed pull requests for the current user' do
      expect(GithubDataCollector).to receive(:username).and_return('login')
      expect(File).to receive(:write).with('test/prefix_login_closed_rawpr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_login_closed_rawrepopr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_login_closed_pr_data.json', any_args).and_return(nil)
      expect(GithubDataCollector).to receive(:get_repo_list).with('user/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_user_prs('test', 'prefix')
    end

    it '.get_org_prs gets a set of closed pull requests for an org' do
      expect(File).to receive(:write).with('test/prefix_testorg_closed_rawpr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_testorg_closed_rawrepopr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_testorg_closed_pr_data.json', any_args).and_return(nil)
      expect(GithubDataCollector).to receive(:get_repo_list).with('orgs/testorg/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_org_prs('test', 'prefix', 'testorg')
    end
  end

  context 'open pull requests' do
    let(:pr_data) {
      { repo_prs: JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'user_open.json'))),
        pr_data: JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'open_pr.json'))) }
    }

    it '.get_user_prs gets a set of open pull requests for a user' do
      expect(File).to receive(:write).thrice.and_return(nil) # Raw data and summary data
      expect(GithubDataCollector).to receive(:get_repo_list).with('users/tester/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'open', state: 'open').and_return(pr_data)

      described_class.get_user_prs('test', 'prefix', 'tester', state: 'open')
    end

    it '.get_org_prs gets a set of open pull requests for an org' do
      expect(File).to receive(:write).thrice.and_return(nil) # Raw data and summary data
      expect(GithubDataCollector).to receive(:get_repo_list).with('orgs/testorg/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'open', state: 'open').and_return(pr_data)

      described_class.get_org_prs('test', 'prefix', 'testorg', state: 'open')
    end

    it '.get_consolidated_user_prs creates a combined file' do
      consolidated_filename = '000000_tester_open_consolidated_pr_data.json'

      # Get user PR stubs
      expect(described_class).to receive(:get_user_prs).with('test', '000000', 'tester', state: 'open')

      # Consolidated file stubs/verification
      expect(described_class).to receive(:file_set).with('test', '*_open_pr_data.json', 'tester').and_return(
        ['000000_01_open_pr_data.json', '000000_02_open_pr_data.json']
      )
      expect(described_class).to receive(:load_file).with('000000_01_open_pr_data.json').and_return(
        filename: '000000_01_open_pr_data.json', pr_data: [repo: 'x', a: 1], file_date: '000000'
      )
      expect(described_class).to receive(:load_file).with('000000_02_open_pr_data.json').and_return(
        filename: '000000_02_open_pr_data.json', pr_data: [repo: 'x', a: 2], file_date: '000000'
      )
      expect(File).to receive(:write).with("test/#{consolidated_filename}",
                                           [file_date: '000000', pr_data: [{ repo: 'x', a: 1.5 }]].to_json).and_return(nil)

      described_class.get_consolidated_user_prs('test', '*_open_pr_data.json', '000000', :repo, 'tester', state: 'open')
    end
  end
end
