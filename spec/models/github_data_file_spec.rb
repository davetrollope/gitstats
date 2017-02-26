require "rails_helper"

RSpec.describe GithubDataFile do
  it "returns a prefix with only the date" do
    allow(Time).to receive(:now).and_return(Time.parse("15/11/2017"))

    expect(described_class.prefix_today).to eq("20171115")
  end

  it "returns a prefix with the date and the hour" do
    allow(Time).to receive(:now).and_return(Time.parse("15/11/2017 01:02:00"))

    expect(described_class.prefix_hour).to eq("20171115_01")
  end

  it "returns a prefix with the date and time" do
    allow(Time).to receive(:now).and_return(Time.parse("15/11/2017 01:02:00"))

    expect(described_class.prefix_datetime).to eq("20171115_010200")
  end

  it "parses multiple files" do
    files = ['a','b']

    expect(JSON).to receive(:parse).twice.and_return(JSON.parse([].to_json))
    allow(File).to receive(:read).and_return([].to_json.to_s)

    data = described_class.load_files files

    expect(data.count).to eq(2)

    expect(files.include?(data[0][:filename])).to be true
    expect(files.include?(data[1][:filename])).to be true
    expect(data[0][:filename]).not_to eq(data[1][:filename])
  end

  it "returns the most recent file" do
    allow(Dir).to receive(:[]).and_return(['a','b'])
    allow(File).to receive(:mtime).and_return(Time.now)

    expect(described_class.most_recent('archive','*')).to eq(['b'])
  end
end