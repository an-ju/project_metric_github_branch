RSpec.describe ProjectMetricGithubBranch do
  context 'meta data' do
    it "has a version number" do
      expect(ProjectMetricGithubBranch::VERSION).not_to be nil
    end
  end

  context 'image and score' do
    subject(:metric) do
      credentials = {github_project: 'https://github.com/an-ju/teamscope', github_token: 'test token'}
      raw_data = File.read 'spec/data/pulls_branches.json'
      described_class.new(credentials, raw_data)
    end

    it 'should generate the right score' do
      expect(metric.score).not_to be_nil
    end

    it 'should set image correctly' do
      expect(metric.image).not_to be_nil
      expect(JSON.parse(metric.image)).to have_key('data')
    end

    it 'should set image contents correctly' do
      image = JSON.parse(metric.image)
      expect(image['data']).to have_key('working_branches')
      expect(image['data']).to have_key('standing_branches')
      expect(image['data']).to have_key('legacy_branches')
    end

  end

  context 'fake data' do
    it 'should generate fake data' do
      expect(described_class.fake_data.length).to eql(3)
    end

    it 'should set image and score' do
      fake_sample = described_class.fake_data.first
      expect(fake_sample).to have_key(:score)
      expect(fake_sample).to have_key(:image)
    end
  end
end
