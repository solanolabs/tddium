# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    protected

    def set_shell
      if !$stdout.tty? || !$stderr.tty? then
        @shell = Thor::Shell::Basic.new
      end
    end

    def env_path(scope, key=nil)
      path = "/#{scope}s/#{get_current_id(scope)}/env"
      path += "/#{key}" if key
      path
    end

    def get_current_id(scope)
      case scope
      when "suite"
        current_suite_id
      when "account"
        current_account_id
      else
        raise "unrecognized scope"
      end
    end

    def environment
      tddium_client.environment.to_sym
    end

    def set_default_environment
      env = options[:environment] || ENV['TDDIUM_CLIENT_ENVIRONMENT']
      if env.nil?
        tddium_client.environment = :development
        tddium_client.environment = :production unless File.exists?(tddium_file_name)
      else
        tddium_client.environment = env.to_sym
      end

      port = options[:port] || ENV['TDDIUM_CLIENT_PORT']
      if port
        tddium_client.port = port.to_i
      end
    end

    def tool_version(tool)
      key = "#{tool}_version".to_sym
      result = tddium_config[key]

      if result
        say Text::Process::CONFIGURED_VERSION % [tool, result]
        return result
      end

      result = `#{tool} -v`.strip
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
