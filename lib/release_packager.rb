require 'fileutils'
require 'tmpdir'
require 'date'
require 'yaml'

require_relative 'release_packager/version'
require_relative 'release_packager/configuration'
require_relative 'release_packager/git_info'
require_relative 'release_packager/packager'

module ReleasePackager
  class Error < StandardError; end
  class GitDirtyError < Error; end
  class ConfigurationError < Error; end
  class ArchiveError < Error; end
end
