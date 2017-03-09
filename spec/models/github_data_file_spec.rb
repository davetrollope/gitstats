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

  it '.load_file parses multiple files' do
    expect(JSON).to receive(:parse).twice.and_return(JSON.parse([].to_json))
    expect(File).to receive(:read).twice.and_return([].to_json.to_s)

    files = %w(a b)
    data = described_class.load_files files

    expect(data.count).to eq(2)
    expect(files.include?(data[0][:filename])).to be true
    expect(files.include?(data[1][:filename])).to be true
    expect(data[0][:filename]).not_to eq(data[1][:filename])
  end

  it '.most_recent returns the most recent file' do
    expect(Dir).to receive(:[]).and_return(%w(a b))
    expect(File).to receive(:mtime).twice.and_return(Time.now)

    expect(described_class.most_recent('archive', '*')).to eq(['b'])
  end

  context 'closed pull requests' do
    let(:pr_data) { { prs: JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'user_closed.json'))), comments: [] } }

    it '.get_user_prs gets a set of closed pull requests for a user' do
      expect(File).to receive(:write).with('test/prefix_tester_closed_rawcomment_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_tester_closed_rawpr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_tester_closed_pr_data.json', any_args).and_return(nil)
      expect(GithubDataCollector).to receive(:get_repo_list).with('users/tester/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_user_prs('test', 'prefix', 'tester')
    end

    it '.get_user_prs gets all closed pull requests for the current user' do
      expect(GithubDataCollector).to receive(:username).and_return('login')
      expect(File).to receive(:write).with('test/prefix_login_closed_rawcomment_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_login_closed_rawpr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_login_closed_pr_data.json', any_args).and_return(nil)
      expect(GithubDataCollector).to receive(:get_repo_list).with('user/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_user_prs('test', 'prefix')
    end

    it '.get_org_prs gets a set of closed pull requests for an org' do
      expect(File).to receive(:write).with('test/prefix_testorg_closed_rawcomment_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_testorg_closed_rawpr_data.json', any_args).and_return(nil)
      expect(File).to receive(:write).with('test/prefix_testorg_closed_pr_data.json', any_args).and_return(nil)
      expect(GithubDataCollector).to receive(:get_repo_list).with('orgs/testorg/repos').and_return(['test_repo'])
      expect(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_org_prs('test', 'prefix', 'testorg')
    end
  end

  context 'open pull requests' do
    let(:pr_data) {
      { prs: JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'user_open.json'))),
        comments: JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'open_comments.json'))) }
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
  end
end
