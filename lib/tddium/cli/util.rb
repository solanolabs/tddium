# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def set_shell
      if !$stdout.tty? || !$stderr.tty? then
        @shell = Thor::Shell::Basic.new
      end
    end

    def tool_version(tool)
      key = "#{tool}_version".to_sym
      result = @repo_config[key]

      if result
        say Text::Process::CONFIGURED_VERSION % [tool, result]
        return result
      end

      begin
        result = `#{tool} -v`.strip
      rescue Errno::ENOENT
        exit_failure("#{tool} is not on PATH; please install and try again")
      end
      say Text::Process::DEPENDENCY_VERSION % [tool, result]
      result
    end

    def warn(msg='')
      STDERR.puts("WARNING: #{msg}")
    end

    def exit_failure(msg='')
      abort msg
    end

    def display_message(message, prefix=' ---> ')
      color = case message["level"]
                when "error" then :red
                when "warn" then :yellow
                else nil
              end
      print prefix
      say message["text"].rstrip, color
    end

    def display_alerts(messages, level, heading)
      return unless messages
      interest = messages.select{|m| [level].include?(m['level'])}
      if interest.size > 0
        say heading
        interest.each do |m|
          display_message(m, '')
        end
      end
    end
  end
end
