require 'spec_helper'

RSpec.describe ReleasePackager::Packager do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      @repo_dir = create_test_repo(File.join(dir, 'repo'))
      @output_dir = File.join(dir, 'releases')
      example.run
    end
  end

  def build_config(overrides = {})
    config_data = {
      'archive_prefix' => 'TestProject',
      'keep' => ['src'],
      'output_dir' => @output_dir,
      'require_clean_git' => false
    }.merge(overrides)

    config_path = create_config_file(@tmpdir, config_data)
    ReleasePackager::Configuration.load(
      File.basename(config_path),
      project_root: @tmpdir
    )
  end

  describe '#run' do
    it 'creates a ZIP archive' do
      config = build_config
      packager = described_class.new(config: config, project_root: @repo_dir)
      packager.run

      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      expect(archives.length).to eq(1)
    end

    it 'includes archive_prefix in filename' do
      config = build_config('archive_prefix' => 'MyApp')
      packager = described_class.new(config: config, project_root: @repo_dir)
      packager.run

      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      expect(File.basename(archives.first)).to start_with('MyApp_')
    end

    it 'includes branch name for non-main branches' do
      system('git', '-C', @repo_dir, 'checkout', '-b', 'feature-x', out: File::NULL, err: File::NULL)
      config = build_config
      packager = described_class.new(config: config, project_root: @repo_dir)
      packager.run

      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      expect(File.basename(archives.first)).to include('feature-x')
    end

    it 'omits branch name for main branches' do
      config = build_config
      packager = described_class.new(config: config, project_root: @repo_dir)
      packager.run

      git_info = ReleasePackager::GitInfo.new(repo_dir: @repo_dir)
      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      # main/master should not appear between date and hash
      expect(File.basename(archives.first)).not_to include("_main_")
      expect(File.basename(archives.first)).not_to include("_master_")
    end
  end

  describe 'whitelist filtering' do
    it 'keeps only whitelisted items' do
      config = build_config('keep' => ['src'])
      packager = described_class.new(config: config, project_root: @repo_dir)

      # Verify by checking the archive contents via a temp extraction
      packager.run

      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      extract_dir = File.join(@tmpdir, 'extracted')

      ps_src = archives.first.tr('/', '\\')
      ps_dest = extract_dir.tr('/', '\\')
      system('powershell', '-Command',
             "Expand-Archive -Path \"#{ps_src}\" -DestinationPath \"#{ps_dest}\" -Force")

      entries = Dir.entries(extract_dir).reject { |e| e == '.' || e == '..' }
      expect(entries).to eq(['src'])
    end
  end

  describe 'exclusions' do
    it 'removes excluded files' do
      # Add a file under src to exclude
      sub_dir = File.join(@repo_dir, 'src', 'config')
      FileUtils.mkdir_p(sub_dir)
      File.write(File.join(sub_dir, 'secret.yml'), 'password: 123')
      system('git', '-C', @repo_dir, 'add', '-A', out: File::NULL, err: File::NULL)
      system('git', '-C', @repo_dir, 'commit', '-m', 'add secret', out: File::NULL, err: File::NULL)

      config = build_config(
        'keep' => ['src'],
        'exclude' => ['src/config/secret.yml']
      )
      packager = described_class.new(config: config, project_root: @repo_dir)
      packager.run

      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      extract_dir = File.join(@tmpdir, 'extracted')

      ps_src = archives.first.tr('/', '\\')
      ps_dest = extract_dir.tr('/', '\\')
      system('powershell', '-Command',
             "Expand-Archive -Path \"#{ps_src}\" -DestinationPath \"#{ps_dest}\" -Force")

      expect(File.exist?(File.join(extract_dir, 'src', 'config', 'secret.yml'))).to be false
    end
  end

  describe 'extra files' do
    it 'copies extra files into the archive' do
      extra_file = File.join(@tmpdir, 'manual.pdf')
      File.write(extra_file, 'PDF content')

      config = build_config(
        'extra_files' => [{
          'source' => extra_file,
          'destination' => 'manual.pdf'
        }]
      )
      packager = described_class.new(config: config, project_root: @repo_dir)
      packager.run

      archives = Dir.glob(File.join(@output_dir, '*.zip'))
      extract_dir = File.join(@tmpdir, 'extracted')

      ps_src = archives.first.tr('/', '\\')
      ps_dest = extract_dir.tr('/', '\\')
      system('powershell', '-Command',
             "Expand-Archive -Path \"#{ps_src}\" -DestinationPath \"#{ps_dest}\" -Force")

      expect(File.exist?(File.join(extract_dir, 'manual.pdf'))).to be true
    end

    it 'warns but continues for optional missing files' do
      config = build_config(
        'extra_files' => [{
          'source' => File.join(@tmpdir, 'nonexistent.pdf'),
          'destination' => 'doc.pdf',
          'optional' => true
        }]
      )
      packager = described_class.new(config: config, project_root: @repo_dir)

      expect { packager.run }.not_to raise_error
    end

    it 'raises error for required missing files' do
      config = build_config(
        'extra_files' => [{
          'source' => File.join(@tmpdir, 'nonexistent.pdf'),
          'destination' => 'doc.pdf'
        }]
      )
      packager = described_class.new(config: config, project_root: @repo_dir)

      expect { packager.run }.to raise_error(ReleasePackager::Error, /Required file not found/)
    end
  end

  describe 'git dirty check' do
    it 'raises GitDirtyError when require_clean_git is true and repo is dirty' do
      File.write(File.join(@repo_dir, 'dirty.txt'), 'dirty')

      config = build_config('require_clean_git' => true)
      packager = described_class.new(config: config, project_root: @repo_dir)

      expect { packager.run }.to raise_error(ReleasePackager::GitDirtyError)
    end

    it 'allows dirty repo when require_clean_git is false' do
      File.write(File.join(@repo_dir, 'dirty.txt'), 'dirty')

      config = build_config('require_clean_git' => false)
      packager = described_class.new(config: config, project_root: @repo_dir)

      expect { packager.run }.not_to raise_error
    end
  end
end
