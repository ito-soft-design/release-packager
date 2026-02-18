module ReleasePackager
  class GitInfo
    attr_reader :branch, :commit_hash, :commit_date

    def initialize(repo_dir: Dir.pwd)
      @repo_dir = File.expand_path(repo_dir)
      fetch_info!
    end

    def clean?
      run_git('status', '--porcelain').strip.empty?
    end

    def main_branch?(main_branches)
      main_branches.include?(@branch)
    end

    private

    def fetch_info!
      @branch = run_git('rev-parse', '--abbrev-ref', 'HEAD').strip
      @commit_hash = run_git('rev-parse', '--short=7', 'HEAD').strip
      raw_date = run_git('show', '-s', '--format=%ci', 'HEAD').strip
      @commit_date = DateTime.parse(raw_date)
    end

    def run_git(*args)
      output = IO.popen(['git', '-C', @repo_dir] + args, err: [:child, :out], &:read)
      unless $?.success?
        raise Error, "git #{args.first} failed: #{output}"
      end
      output
    end
  end
end
