require 'tmpdir'
require 'fileutils'
require 'release_packager'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.order = :random
end

# Create a minimal YAML config file in a temp directory and return the path
def create_config_file(dir, config = {})
  defaults = {
    'archive_prefix' => 'TestProject',
    'keep' => ['src']
  }
  merged = defaults.merge(config)

  path = File.join(dir, 'release.yml')
  File.write(path, YAML.dump(merged))
  path
end

# Create a temporary git repository with an initial commit
def create_test_repo(dir)
  system('git', 'init', dir, out: File::NULL, err: File::NULL)
  system('git', '-C', dir, 'config', 'user.email', 'test@test.com')
  system('git', '-C', dir, 'config', 'user.name', 'Test')

  # Create some files
  FileUtils.mkdir_p(File.join(dir, 'src'))
  FileUtils.mkdir_p(File.join(dir, 'docs'))
  File.write(File.join(dir, 'src', 'main.rb'), '# main')
  File.write(File.join(dir, 'docs', 'readme.txt'), 'readme')
  File.write(File.join(dir, 'secret.txt'), 'secret')

  system('git', '-C', dir, 'add', '-A', out: File::NULL, err: File::NULL)
  system('git', '-C', dir, 'commit', '-m', 'initial commit', out: File::NULL, err: File::NULL)
  dir
end
