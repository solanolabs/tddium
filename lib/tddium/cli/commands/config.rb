# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    desc "config [SCOPE=suite]", "Display config variables for SCOPE (account, repo, suite)"
    def config(scope="suite")
      set_shell
      set_default_environment
      user_details = user_logged_in?(true, true)
      exit_failure unless user_details

      begin
        config_details = call_api(:get, env_path(scope))
        show_config_details(config_details)
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::LIST_CONFIG_ERROR
      end
    end

    desc "config:add [SCOPE] [KEY] [VALUE]", "Set KEY=VALUE at SCOPE (of account, repo, suite)"
    define_method "config:add" do |scope, key, value|
      set_shell
      set_default_environment
      user_details = user_logged_in?(true, true)
      exit_failure unless user_details

      begin
        say Text::Process::ADD_CONFIG % [scope, key, value]
        result = call_api(:post, Api::Path::KEYS, :keys=>[keydata])
        say Text::Process::ADD_CONFIG_DONE % [scope, key, value]
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::ADD_CONFIG_ERROR
      end
    end

    desc "config:remove [SCOPE] [KEY]", "Remove config variable NAME from SCOPE"
    define_method "config:remove" do |scope, name|
      set_shell
      set_default_environment
      user_details = user_logged_in?(true, true)
      exit_failure unless user_details
      begin
        say Text::Process::REMOVE_CONFIG % [scope, key, value]
        result = call_api(:post, Api::Path::KEYS, :keys=>[keydata])
        say Text::Process::REMOVE_CONFIG_DONE % [scope, key, value]
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::REMOVE_CONFIG_ERROR
      end
    end

    private

      def show_config_details(config_data)
        say Text::Status::CONFIG_DETAILS
        if config_data.length == 0
          say Text::Process::NO_CONFIG
        else
          config_data.each do |k,v| 
            say "#{k}=#{v}"
          end
        end
        say Text::Process::CONFIG_EDIT_COMMANDS
      end
  end
end  
