require 'rake'
require 'rake/tasklib'
require_relative '../release_packager'

module ReleasePackager
  class RakeTask < ::Rake::TaskLib
    CONFIG_TEMPLATE = <<~YAML
      # Output directory (relative to project root)
      output_dir: ../releases

      # Archive filename prefix
      archive_prefix: MyProject

      # Date format (Ruby strftime)
      # date_format: "%Y%m%d_%H%M%S"

      # Main branch names (branch name is omitted from archive filename)
      # main_branches:
      #   - master
      #   - main

      # Require clean git working tree
      # require_clean_git: true

      # Files and folders to include in the release (whitelist)
      keep:
        - src
        - README.md

      # Specific files to exclude from the whitelist
      # exclude:
      #   - config/secrets.yml

      # Extra files to add from outside the repository
      # extra_files:
      #   - source: build/output.pdf
      #     destination: output.pdf
      #     optional: true
    YAML

    attr_accessor :name, :config_file, :project_root

    def initialize(name = :release, config_file: 'release.yml', project_root: nil)
      @name = name
      @config_file = config_file
      @project_root = project_root || Dir.pwd
      yield self if block_given?
      define_task
    end

    private

    def define_task
      desc "Create release archive"
      task @name do
        config = load_config
        packager = Packager.new(config: config, project_root: @project_root)
        packager.run
      end

      namespace @name do
        desc "Create release archive for preview (skips clean check, adds PREVIEW_ prefix)"
        task :try do
          config = load_config
          config.require_clean_git = false
          config.archive_prefix = "PREVIEW_#{config.archive_prefix}"
          packager = Packager.new(config: config, project_root: @project_root)
          packager.run
        end

        desc "Generate a sample #{@config_file}"
        task :init do
          dest = File.join(@project_root, @config_file)
          if File.exist?(dest)
            puts "#{@config_file} already exists. Skipping."
          else
            File.write(dest, CONFIG_TEMPLATE)
            puts "Created #{@config_file}"
          end
        end
      end
    end

    def load_config
      Configuration.load(@config_file, project_root: @project_root)
    end
  end
end
