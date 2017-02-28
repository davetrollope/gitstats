require 'rails_helper'

RSpec.describe GithubDataFile do
  it '.prefix_today returns a prefix with only the date' do
    allow(Time).to receive(:now).and_return(Time.parse('15/11/2017'))

    expect(described_class.prefix_today).to eq('20171115')
  end

  it '.prefix_hour returns a prefix with the date and the hour' do
    allow(Time).to receive(:now).and_return(Time.parse('15/11/2017 01:02:00'))

    expect(described_class.prefix_hour).to eq('20171115_01')
  end

  it '.prefix_datetime returns a prefix with the date and time' do
    allow(Time).to receive(:now).and_return(Time.parse('15/11/2017 01:02:00'))

    expect(described_class.prefix_datetime).to eq('20171115_010200')
  end

  it '.load_file parses multiple files' do
    expect(JSON).to receive(:parse).twice.and_return(JSON.parse([].to_json))
    allow(File).to receive(:read).and_return([].to_json.to_s)

    files = %w(a b)
    data = described_class.load_files files

    expect(data.count).to eq(2)
    expect(files.include?(data[0][:filename])).to be true
    expect(files.include?(data[1][:filename])).to be true
    expect(data[0][:filename]).not_to eq(data[1][:filename])
  end

  it '.most_recent returns the most recent file' do
    allow(Dir).to receive(:[]).and_return(%w(a b))
    allow(File).to receive(:mtime).and_return(Time.now)

    expect(described_class.most_recent('archive', '*')).to eq(['b'])
  end

  context 'closed pull requests' do
    let(:pr_data) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'user_closed.json'))) }

    it '.get_user_prs gets a set of closed pull requests for a user' do
      allow(File).to receive(:write).twice.and_return(nil) # Raw data and summary data
      allow(GithubDataCollector).to receive(:get_repo_list).with('users/tester/repos').and_return(['test_repo'])
      allow(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_user_prs('test', 'prefix', 'tester')
    end

    it '.get_user_prs gets all closed pull requests for the current user' do
      allow(File).to receive(:write).twice.and_return(nil) # Raw data and summary data
      allow(GithubDataCollector).to receive(:get_repo_list).with('user/repos').and_return(['test_repo'])
      allow(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_user_prs('test', 'prefix')
    end

    it '.get_org_prs gets a set of closed pull requests for an org' do
      allow(File).to receive(:write).twice.and_return(nil) # Raw data and summary data
      allow(GithubDataCollector).to receive(:get_repo_list).with('orgs/testorg/repos').and_return(['test_repo'])
      allow(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'closed', {}).and_return(pr_data)

      described_class.get_org_prs('test', 'prefix', 'testorg')
    end
  end

  context 'open pull requests' do
    let(:pr_data) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'user_open.json'))) }

    it '.get_user_prs gets a set of open pull requests for a user' do
      allow(File).to receive(:write).twice.and_return(nil) # Raw data and summary data
      allow(GithubDataCollector).to receive(:get_repo_list).with('users/tester/repos').and_return(['test_repo'])
      allow(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'open', state: 'open').and_return(pr_data)

      described_class.get_user_prs('test', 'prefix', 'tester', state: 'open')
    end

    it '.get_org_prs gets a set of open pull requests for an org' do
      allow(File).to receive(:write).twice.and_return(nil) # Raw data and summary data
      allow(GithubDataCollector).to receive(:get_repo_list).with('orgs/testorg/repos').and_return(['test_repo'])
      allow(GithubDataCollector).to receive(:get_prs).with('test', ['test_repo'], 'open', state: 'open').and_return(pr_data)

      described_class.get_org_prs('test', 'prefix', 'testorg', state: 'open')
    end
  end
end
