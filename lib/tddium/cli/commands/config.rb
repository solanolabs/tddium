# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "config [SCOPE]", "Display config variables for SCOPE (account or suite, default: suite)"
    def config(scope="suite")
      tddium_setup({:repo => true, :suite => true})

      begin
        config_details = @tddium_api.get_config_key(scope)
        show_config_details(scope, config_details['env'])
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::LIST_CONFIG_ERROR
      end
    end

    desc "config:add [SCOPE] [KEY] [VALUE]", "Set KEY=VALUE at SCOPE (account or suite)"
    define_method "config:add" do |scope, key, value|
      tddium_setup({:repo => true, :suite => true})

      begin
        say Text::Process::ADD_CONFIG % [key, value, scope]
        result = @tddium_api.set_config_key(scope, key, value)
        say Text::Process::ADD_CONFIG_DONE % [key, value, scope]
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::ADD_CONFIG_ERROR
      end
    end

    desc "config:remove [SCOPE] [KEY]", "Remove config variable NAME from SCOPE"
    define_method "config:remove" do |scope, key|
      tddium_setup({:repo => true, :suite => true})

      begin
        say Text::Process::REMOVE_CONFIG % [key, scope]
        result = @tddium_api.delete_config_key(scope, key)
        say Text::Process::REMOVE_CONFIG_DONE % [key, scope]
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::REMOVE_CONFIG_ERROR
      end
    end
  end
end  
