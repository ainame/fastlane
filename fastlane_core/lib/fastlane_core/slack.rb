module FastlaneCore
  class Slack
    # This is a substitue of this LinkFormatter in slack-notifier
    # https://github.com/stevenosloan/slack-notifier/blob/4bf6582663dc9e5070afe3fdc42d67c14a513354/lib/slack-notifier/util/link_formatter.rb
    class LinkConverter
      HTML_PATTERN = %r{<a .*? href=['"](?<link>#{URI.regexp})['"].*?>(?<label>.+?)<\/a>}
      MARKDOWN_PATTERN = %r{\[(?<label>[^\[\]]*?)\]\((?<link>)#{URI.regexp}|(mailto:#{URI::MailTo::EMAIL_REGEXP}))\)}

      def self.format(string)
        convert_markdown_to_slack_link(convert_html_to_slack_link(string.scrub))
      end

      def self.convert_html_to_slack_link(string)
        string.gsub(HTML_PATTERN) do |match|
          slack_link(Regexp.last_match[:link], Regexp.last_match[:label])
        end
      end

      def self.convert_markdown_to_slack_link(string)
        string.gsub(MARKDOWN_PATTERN) do |match|
          slack_link(Regexp.last_match[:link], Regexp.last_match[:label])
        end
      end

      def self.slack_link(href, text)
        return "<#{href}>" if text.nil? || text.empty?
        "<#{href}|#{text}>"
      end
    end
  end
end
