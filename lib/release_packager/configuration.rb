module ReleasePackager
  class Configuration
    DEFAULTS = {
      'output_dir' => '../releases',
      'date_format' => '%Y%m%d_%H%M%S',
      'main_branches' => ['master', 'main'],
      'require_clean_git' => true,
      'keep' => [],
      'exclude' => [],
      'extra_files' => []
    }.freeze

    attr_reader :output_dir, :archive_prefix, :date_format,
                :main_branches, :require_clean_git,
                :keep, :exclude, :extra_files

    def initialize(config_path, project_root: Dir.pwd)
      @project_root = File.expand_path(project_root)
      raw = load_yaml(config_path)
      config = DEFAULTS.merge(raw)

      @output_dir = config['output_dir']
      @archive_prefix = config['archive_prefix']
      @date_format = config['date_format']
      @main_branches = config['main_branches']
      @require_clean_git = config['require_clean_git']
      @keep = config['keep']
      @exclude = config['exclude']
      @extra_files = config['extra_files']

      validate!
      resolve_paths!
    end

    def self.load(config_path = 'release.yml', project_root: Dir.pwd)
      full_path = File.expand_path(config_path, project_root)
      unless File.exist?(full_path)
        raise ConfigurationError, "Configuration file not found: #{full_path}"
      end

      new(full_path, project_root: project_root)
    end

    private

    def load_yaml(path)
      YAML.load_file(path) || {}
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "YAML syntax error: #{e.message}"
    end

    def validate!
      if @archive_prefix.nil? || @archive_prefix.to_s.strip.empty?
        raise ConfigurationError, "archive_prefix is required"
      end

      if @keep.nil? || !@keep.is_a?(Array) || @keep.empty?
        raise ConfigurationError, "keep must contain at least one item"
      end

      @extra_files.each do |entry|
        unless entry.is_a?(Hash) && entry['source'] && entry['destination']
          raise ConfigurationError, "Each extra_files entry must have 'source' and 'destination'"
        end
      end
    end

    def resolve_paths!
      @output_dir = File.expand_path(@output_dir, @project_root)

      @extra_files = @extra_files.map do |entry|
        entry.merge('source' => File.expand_path(entry['source'], @project_root))
      end
    end
  end
end
