describe Fastlane do
  describe Fastlane::FastFile do
    describe "changelog_from_git_commits" do
      it "Collects messages from the last tag to HEAD by default" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits
        end").runner.execute(:test)

        inner_command =  "git describe --tags `git rev-list --tags --max-count=1`"
        # this is not really the command that would have been executed, but a "fabricated" representation for tests (by Actions.sh) that includes both command that would have been run
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD" 
        expect(result).to eq(pseudocommand)
      end

      it "Uses the provided pretty format to collect log messages" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(pretty: '%s%n%b')
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%s%n%b\" #{inner_command.shellescape}...HEAD"
        expect(result).to eq(pseudocommand)
      end

      it "Uses the provided date format to collect log messages if specified" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(pretty: '%s%n%b', date_format: 'short')
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%s%n%b\" --date=\"short\" #{inner_command.shellescape}...HEAD"
        expect(result).to eq(pseudocommand)
      end

      it "Does not match lightweight tags when searching for the last one if so requested" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(match_lightweight_tag: false)
        end").runner.execute(:test)

        inner_command = "git describe `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD"
        expect(result).to eq(pseudocommand)
      end

      it "Collects logs in the specified revision range if specified" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(between: ['abcd', '1234'])
        end").runner.execute(:test)

        expect(result).to eq("git log --pretty=\"%B\" abcd...1234")
      end

      it "Handles tag names with characters that need shell escaping" do
        tag = 'v1.8.0(30)'
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(between: ['#{tag}', 'HEAD'])
        end").runner.execute(:test)

        expect(result).to eq("git log --pretty=\"%B\" #{tag.shellescape}...HEAD")
      end

      it "Does not accept a :between array of size 1" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            changelog_from_git_commits(between: ['abcd'])
          end").runner.execute(:test)
        end.to raise_error(":between must be an array of size 2")
      end

      it "Does not accept a :between array with nil values" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            changelog_from_git_commits(between: ['abcd', nil])
          end").runner.execute(:test)
        end.to raise_error(":between must not contain nil values")
      end

      it "Converts a string value for :commits_count" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(commits_count: '10')
        end").runner.execute(:test)

        expect(result).to eq("git log --pretty=\"%B\" -n 10")
      end

      it "Does not accept a :commits_count and :between at the same time" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            changelog_from_git_commits(commits_count: 10, between: ['abcd', '1234'])
          end").runner.execute(:test)
        end.to raise_error("Unresolved conflict between options: 'commits_count' and 'between'")
      end

      it "Does not accept a :commits_count < 1" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            changelog_from_git_commits(commits_count: -1)
          end").runner.execute(:test)
        end.to raise_error(":commits_count must be >= 1")
      end

      it "Collects logs with specified number of commits" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(commits_count: 10)
        end").runner.execute(:test)

        expect(result).to eq("git log --pretty=\"%B\" -n 10")
      end

      it "Does not accept an invalid value for :merge_commit_filtering" do
        values = Fastlane::Actions::GIT_MERGE_COMMIT_FILTERING_OPTIONS.map { |o| "'#{o}'" }.join(', ')
        error_msg = "Valid values for :merge_commit_filtering are #{values}"

        expect do
          Fastlane::FastFile.new.parse("lane :test do
            changelog_from_git_commits(merge_commit_filtering: 'invalid')
          end").runner.execute(:test)
        end.to raise_error(error_msg)
      end

      it "Does not include merge commits in the list of commits" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(include_merges: false)
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD --no-merges"
        expect(result).to eq(pseudocommand)
      end

      it "Only include merge commits if merge_commit_filtering is only_include_merges" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(merge_commit_filtering: 'only_include_merges')
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD --merges"
        expect(result).to eq(pseudocommand)
      end

      it "Include merge commits if merge_commit_filtering is include_merges" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(merge_commit_filtering: 'include_merges')
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD"
        expect(result).to eq(pseudocommand)
      end

      it "Does not include merge commits if merge_commit_filtering is exclude_merges" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(merge_commit_filtering: 'exclude_merges')
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD --no-merges"
        expect(result).to eq(pseudocommand)
      end

      it "Uses pattern matching for tag name if requested" do
        tag_match_pattern = '*1.8*'
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(tag_match_pattern: '#{tag_match_pattern}')
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags=#{tag_match_pattern.shellescape} --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD"
        expect(result).to eq(pseudocommand)
      end

      it "Does not use pattern matching for tag name if so requested" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits()
        end").runner.execute(:test)

        inner_command = "git describe --tags `git rev-list --tags --max-count=1`"
        pseudocommand = "git log --pretty=\"%B\" #{inner_command.shellescape}...HEAD"
        expect(result).to eq(pseudocommand)
      end

      it "Runs between option from command line" do
        expect(system("fastlane run changelog_from_git_commits between:123456,HEAD")).to be
      end

      it "Accepts string value for :between" do
        result = Fastlane::FastFile.new.parse("lane :test do
          changelog_from_git_commits(between: 'abcd,1234')
        end").runner.execute(:test)

        expect(result).to eq("git log --pretty=\"%B\" abcd...1234")
      end

      it "Does not accept string if it does not contain comma" do
        expect do
          result = Fastlane::FastFile.new.parse("lane :test do
            changelog_from_git_commits(between: 'abcd1234')
          end").runner.execute(:test)
        end.to raise_error(":between must contain comma")
      end
    end
  end
end
