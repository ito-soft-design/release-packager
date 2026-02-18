require 'rake'
require 'rake/tasklib'
require_relative '../release_packager'

module ReleasePackager
  class RakeTask < ::Rake::TaskLib
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
        config = Configuration.load(@config_file, project_root: @project_root)
        packager = Packager.new(config: config, project_root: @project_root)
        packager.run
      end
    end
  end
end
