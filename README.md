# release_packager

A Ruby gem that creates release ZIP archives from Git repositories.
Configure whitelists, exclusions, and extra files via a YAML configuration file.

[日本語版 README](README.ja.md)

## Installation

Add to your Gemfile:

```ruby
gem 'release_packager', path: '<path to gem>'
```

```bash
bundle install
```

## Setup

### 1. Create release.yml

Create `release.yml` in your project root.

```yaml
# Output directory (relative to project root)
output_dir: ../releases

# Archive filename prefix
archive_prefix: MyProject

# Date format (Ruby strftime)
date_format: "%Y%m%d_%H%M%S"

# Main branch names (branch name is omitted from archive filename)
main_branches:
  - master
  - main

# Require clean git working tree
require_clean_git: true

# Files and folders to include in the release (whitelist)
keep:
  - src
  - config
  - README.md

# Specific files to exclude from the whitelist
exclude:
  - config/secrets.yml

# Extra files to add from outside the repository
extra_files:
  - source: build/output.pdf
    destination: output.pdf
    optional: true  # Warn instead of fail if missing (default: false)
```

### 2. Add to Rakefile

```ruby
require 'release_packager/rake_task'

ReleasePackager::RakeTask.new(:release)
```

## Usage

```bash
bundle exec rake release
```

### Archive filename format

```
{archive_prefix}_{datetime}_{branch}_{commit_hash}.zip
```

Branch name is omitted when the current branch is listed in `main_branches`.

Examples:
- main branch: `MyProject_20260218_120000_abc1234.zip`
- feature branch: `MyProject_20260218_120000_feature-x_abc1234.zip`

## Configuration

| Key | Required | Default | Description |
|-----|----------|---------|-------------|
| `archive_prefix` | Yes | - | Archive filename prefix |
| `keep` | Yes | - | Files and folders to include |
| `output_dir` | No | `../releases` | Output directory |
| `date_format` | No | `%Y%m%d_%H%M%S` | Date format |
| `main_branches` | No | `[master, main]` | Main branch names |
| `require_clean_git` | No | `true` | Require clean working tree |
| `exclude` | No | `[]` | Files to exclude |
| `extra_files` | No | `[]` | Extra files to add |

## How it works

1. Check Git status (if `require_clean_git: true`)
2. Clone the repository to a temporary directory
3. Remove files and folders not in the `keep` list
4. Remove files in the `exclude` list
5. Copy `extra_files` into the archive
6. Create ZIP using PowerShell `Compress-Archive`

## Requirements

- Ruby 3.0+
- Git
- Windows (uses PowerShell for ZIP creation)
