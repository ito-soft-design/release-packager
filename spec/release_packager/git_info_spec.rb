require 'spec_helper'

RSpec.describe ReleasePackager::GitInfo do
  around do |example|
    Dir.mktmpdir do |dir|
      @repo_dir = create_test_repo(dir)
      example.run
    end
  end

  describe '#branch' do
    it 'returns the current branch name' do
      git_info = described_class.new(repo_dir: @repo_dir)
      # git init creates 'main' or 'master' depending on config
      expect(git_info.branch).to match(/\A(main|master)\z/)
    end
  end

  describe '#commit_hash' do
    it 'returns a 7-character commit hash' do
      git_info = described_class.new(repo_dir: @repo_dir)
      expect(git_info.commit_hash).to match(/\A[0-9a-f]{7}\z/)
    end
  end

  describe '#commit_date' do
    it 'returns a DateTime object' do
      git_info = described_class.new(repo_dir: @repo_dir)
      expect(git_info.commit_date).to be_a(DateTime)
    end
  end

  describe '#clean?' do
    it 'returns true when working tree is clean' do
      git_info = described_class.new(repo_dir: @repo_dir)
      expect(git_info.clean?).to be true
    end

    it 'returns false when there are uncommitted changes' do
      File.write(File.join(@repo_dir, 'new_file.txt'), 'new content')
      git_info = described_class.new(repo_dir: @repo_dir)
      expect(git_info.clean?).to be false
    end
  end

  describe '#main_branch?' do
    it 'returns true when branch is in the list' do
      git_info = described_class.new(repo_dir: @repo_dir)
      expect(git_info.main_branch?(['main', 'master'])).to be true
    end

    it 'returns false when branch is not in the list' do
      git_info = described_class.new(repo_dir: @repo_dir)
      expect(git_info.main_branch?(['production'])).to be false
    end
  end

  describe 'error handling' do
    it 'raises Error for non-existent repo' do
      expect {
        described_class.new(repo_dir: '/nonexistent/path')
      }.to raise_error(ReleasePackager::Error)
    end
  end
end
