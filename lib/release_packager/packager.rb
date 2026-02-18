module ReleasePackager
  class Packager
    def initialize(config:, project_root: Dir.pwd)
      @config = config
      @project_root = File.expand_path(project_root)
    end

    def run
      git_info = GitInfo.new(repo_dir: @project_root)
      check_clean_status!(git_info)

      archive_name = build_archive_name(git_info)
      FileUtils.mkdir_p(@config.output_dir)
      archive_path = File.join(@config.output_dir, archive_name)

      Dir.mktmpdir do |tmpdir|
        staging_dir = File.join(tmpdir, 'repo')
        clone_repo(staging_dir)
        apply_whitelist(staging_dir)
        apply_exclusions(staging_dir)
        copy_extra_files(staging_dir)
        create_zip(staging_dir, archive_path)
      end

      report_success(archive_path, git_info)
    end

    private

    def check_clean_status!(git_info)
      return unless @config.require_clean_git
      return if git_info.clean?

      status = IO.popen(['git', '-C', @project_root, 'status', '--porcelain'], &:read).strip
      raise GitDirtyError,
        "There are uncommitted changes. Please commit all changes before running.\n\nChanged files:\n#{status}"
    end

    def build_archive_name(git_info)
      date_str = git_info.commit_date.strftime(@config.date_format)
      parts = [@config.archive_prefix, date_str]

      unless git_info.main_branch?(@config.main_branches)
        parts << git_info.branch
      end

      parts << git_info.commit_hash
      "#{parts.join('_')}.zip"
    end

    def clone_repo(dest)
      puts "Cloning repository to temporary directory..."
      unless system('git', 'clone', @project_root, dest)
        raise Error, "git clone failed"
      end
    end

    def apply_whitelist(staging_dir)
      puts "Removing unnecessary files and folders..."
      Dir.entries(staging_dir).each do |item|
        next if item == '.' || item == '..'
        next if @config.keep.include?(item)

        item_path = File.join(staging_dir, item)
        FileUtils.rm_rf(item_path)
        puts "  Removed: #{item}"
      end
    end

    def apply_exclusions(staging_dir)
      @config.exclude.each do |file|
        file_path = File.join(staging_dir, file)
        if File.exist?(file_path)
          FileUtils.rm_rf(file_path)
          puts "  Removed: #{file}"
        end
      end
    end

    def copy_extra_files(staging_dir)
      return if @config.extra_files.empty?

      puts "Adding extra files..."
      @config.extra_files.each do |entry|
        source = entry['source']
        dest = File.join(staging_dir, entry['destination'])

        if File.exist?(source)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(source, dest)
          puts "  Added: #{entry['destination']}"
        elsif entry['optional']
          puts "  Warning: #{entry['destination']} not found (skipped)"
        else
          raise Error, "Required file not found: #{source}"
        end
      end
    end

    def create_zip(staging_dir, archive_path)
      archive_name = File.basename(archive_path)
      puts "Creating archive: #{archive_name}..."

      ps_source = staging_dir.tr('/', '\\')
      ps_dest = archive_path.tr('/', '\\')

      powershell_cmd = "Compress-Archive -Path \"#{ps_source}\\*\" -DestinationPath \"#{ps_dest}\" -Force"
      system('powershell', '-Command', powershell_cmd)

      unless File.exist?(archive_path)
        raise ArchiveError, "Failed to create archive: #{archive_path}"
      end
    end

    def report_success(archive_path, git_info)
      date_str = git_info.commit_date.strftime(@config.date_format)
      size = (File.size(archive_path) / 1024.0 / 1024.0).round(2)
      puts ""
      puts "Release archive created successfully!"
      puts "  Location: #{archive_path}"
      puts "  Size: #{size} MB"
      puts "  Branch: #{git_info.branch}"
      puts "  Commit: #{git_info.commit_hash}"
      puts "  Date: #{date_str}"
    end
  end
end
