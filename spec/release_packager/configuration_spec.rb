require 'spec_helper'

RSpec.describe ReleasePackager::Configuration do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  describe '.load' do
    it 'raises ConfigurationError when file does not exist' do
      expect {
        described_class.load('nonexistent.yml', project_root: @tmpdir)
      }.to raise_error(ReleasePackager::ConfigurationError, /Configuration file not found/)
    end

    it 'loads a valid config file' do
      create_config_file(@tmpdir)
      config = described_class.load('release.yml', project_root: @tmpdir)
      expect(config.archive_prefix).to eq('TestProject')
    end
  end

  describe 'default values' do
    it 'applies defaults for optional fields' do
      create_config_file(@tmpdir)
      config = described_class.load('release.yml', project_root: @tmpdir)

      expect(config.date_format).to eq('%Y%m%d_%H%M%S')
      expect(config.main_branches).to eq(['master', 'main'])
      expect(config.require_clean_git).to eq(true)
      expect(config.exclude).to eq([])
      expect(config.extra_files).to eq([])
    end

    it 'uses output_dir default of ../releases resolved against project root' do
      create_config_file(@tmpdir)
      config = described_class.load('release.yml', project_root: @tmpdir)

      expected = File.expand_path('../releases', @tmpdir)
      expect(config.output_dir).to eq(expected)
    end
  end

  describe 'custom values' do
    it 'overrides defaults with YAML values' do
      create_config_file(@tmpdir, {
        'output_dir' => './dist',
        'date_format' => '%Y%m%d',
        'main_branches' => ['production'],
        'require_clean_git' => false
      })
      config = described_class.load('release.yml', project_root: @tmpdir)

      expect(config.date_format).to eq('%Y%m%d')
      expect(config.main_branches).to eq(['production'])
      expect(config.require_clean_git).to eq(false)
      expect(config.output_dir).to eq(File.expand_path('dist', @tmpdir))
    end
  end

  describe 'validation' do
    it 'raises error when archive_prefix is missing' do
      create_config_file(@tmpdir, { 'archive_prefix' => nil })
      expect {
        described_class.load('release.yml', project_root: @tmpdir)
      }.to raise_error(ReleasePackager::ConfigurationError, /archive_prefix is required/)
    end

    it 'raises error when archive_prefix is empty string' do
      create_config_file(@tmpdir, { 'archive_prefix' => '  ' })
      expect {
        described_class.load('release.yml', project_root: @tmpdir)
      }.to raise_error(ReleasePackager::ConfigurationError, /archive_prefix is required/)
    end

    it 'warns when keep is empty' do
      create_config_file(@tmpdir, { 'keep' => [] })
      expect {
        described_class.load('release.yml', project_root: @tmpdir)
      }.to output(/Warning: keep list is empty/).to_stderr
    end

    it 'raises error when extra_files entry is missing source' do
      create_config_file(@tmpdir, {
        'extra_files' => [{ 'destination' => 'out.txt' }]
      })
      expect {
        described_class.load('release.yml', project_root: @tmpdir)
      }.to raise_error(ReleasePackager::ConfigurationError, /source.*destination/)
    end

    it 'raises error when extra_files entry is missing destination' do
      create_config_file(@tmpdir, {
        'extra_files' => [{ 'source' => 'in.txt' }]
      })
      expect {
        described_class.load('release.yml', project_root: @tmpdir)
      }.to raise_error(ReleasePackager::ConfigurationError, /source.*destination/)
    end
  end

  describe 'path resolution' do
    it 'resolves extra_files source paths relative to project root' do
      create_config_file(@tmpdir, {
        'extra_files' => [{
          'source' => 'build/doc.pdf',
          'destination' => 'doc.pdf'
        }]
      })
      config = described_class.load('release.yml', project_root: @tmpdir)

      expected_source = File.expand_path('build/doc.pdf', @tmpdir)
      expect(config.extra_files.first['source']).to eq(expected_source)
    end

    it 'preserves destination as relative path' do
      create_config_file(@tmpdir, {
        'extra_files' => [{
          'source' => 'build/doc.pdf',
          'destination' => 'doc.pdf'
        }]
      })
      config = described_class.load('release.yml', project_root: @tmpdir)

      expect(config.extra_files.first['destination']).to eq('doc.pdf')
    end
  end

  describe 'YAML syntax error' do
    it 'raises ConfigurationError for invalid YAML' do
      File.write(File.join(@tmpdir, 'bad.yml'), ":\ninvalid: [yaml\n")
      expect {
        described_class.load('bad.yml', project_root: @tmpdir)
      }.to raise_error(ReleasePackager::ConfigurationError, /YAML syntax error/)
    end
  end
end
