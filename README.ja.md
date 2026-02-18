# release_packager

Git リポジトリからリリース用 ZIP アーカイブを作成する Ruby gem です。
YAML 設定ファイルでホワイトリスト・除外リスト・追加ファイルなどを指定できます。

[English README](README.md)

## インストール

Gemfile に以下を追加:

```ruby
gem 'release_packager', path: '<gemへのパス>'
```

```bash
bundle install
```

## セットアップ

### 1. release.yml を作成

プロジェクトルートに `release.yml` を作成します。

```yaml
# 出力先ディレクトリ (プロジェクトルートからの相対パス)
output_dir: ../releases

# アーカイブファイル名のプレフィックス
archive_prefix: MyProject

# 日時フォーマット (Ruby strftime)
date_format: "%Y%m%d_%H%M%S"

# メインブランチ名 (アーカイブ名にブランチ名を含めない)
main_branches:
  - master
  - main

# コミットされていない変更がある場合にエラーにするか
require_clean_git: true

# リリースに含めるファイル・フォルダ (ホワイトリスト)
keep:
  - src
  - config
  - README.md

# ホワイトリスト内で除外する特定ファイル
exclude:
  - config/secrets.yml

# Git管理外のファイルをアーカイブに追加
extra_files:
  - source: build/output.pdf
    destination: output.pdf
    optional: true  # ファイルがなくても警告のみ (デフォルト: false)
```

### 2. Rakefile に追加

```ruby
require 'release_packager/rake_task'

ReleasePackager::RakeTask.new(:release)
```

## 使い方

```bash
bundle exec rake release
```

### アーカイブのファイル名

```
{archive_prefix}_{日時}_{ブランチ名}_{コミットハッシュ}.zip
```

`main_branches` に含まれるブランチの場合はブランチ名が省略されます。

例:
- main ブランチ: `MyProject_20260218_120000_abc1234.zip`
- feature ブランチ: `MyProject_20260218_120000_feature-x_abc1234.zip`

## 設定項目

| キー | 必須 | デフォルト | 説明 |
|------|------|-----------|------|
| `archive_prefix` | Yes | - | アーカイブファイル名のプレフィックス |
| `keep` | Yes | - | リリースに含めるファイル・フォルダのリスト |
| `output_dir` | No | `../releases` | 出力先ディレクトリ |
| `date_format` | No | `%Y%m%d_%H%M%S` | 日時フォーマット |
| `main_branches` | No | `[master, main]` | メインブランチ名のリスト |
| `require_clean_git` | No | `true` | 未コミット変更時にエラーにするか |
| `exclude` | No | `[]` | 除外する特定ファイルのリスト |
| `extra_files` | No | `[]` | 追加ファイルのリスト |

## 動作の流れ

1. Git の状態を確認 (`require_clean_git: true` の場合)
2. リポジトリを一時ディレクトリにクローン
3. `keep` リストに含まれないファイル・フォルダを削除
4. `exclude` リストのファイルを削除
5. `extra_files` のファイルをコピー
6. PowerShell の `Compress-Archive` で ZIP を作成

## 動作環境

- Ruby 3.0 以上
- Git
- Windows (ZIP 作成に PowerShell を使用)
