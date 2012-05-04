# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def prompt(text, current_value, default_value, dont_prompt=false)
      value = current_value || (dont_prompt ? nil : ask(text % default_value, :bold))
      (value.nil? || value.empty?) ? default_value : value
    end

    def prompt_missing_ssh_key
      keys = @tddium_api.get_keys
      if keys.empty? then
        say Text::Process::SSH_KEY_NEEDED
        keydata = prompt_ssh_key(nil)
        result = @tddium_api.set_keys({:keys => [keydata]})
        return true
      end
      false
    rescue TddiumError => e
      exit_failure e.message
    rescue TddiumClient::Error::API => e
      exit_failure e.explanation
    end

    def prompt_ssh_key(current, name='default')
      # Prompt for ssh-key file
      ssh_file = prompt(Text::Prompt::SSH_KEY, current, Default::SSH_FILE)
      Tddium::Ssh.load_ssh_key(ssh_file, name)
    end

    def prompt_suite_params(options, params, current={})
      say Text::Process::DETECTED_BRANCH % params[:branch] if params[:branch]
      params[:ruby_version] = tool_version(:ruby)
      params[:bundler_version] = tool_version(:bundle)
      params[:rubygems_version] = tool_version(:gem)

      ask_or_update = lambda do |key, text, default|
        params[key] = prompt(text, options[key], current.fetch(key.to_s, default), options[:non_interactive])
      end

      pattern = configured_test_pattern

      if pattern.is_a?(Array)
        say Text::Process::CONFIGURED_PATTERN % pattern.map{|p| " - #{p}"}.join("\n")
        params[:test_pattern] = pattern.join(",")
      elsif pattern
        exit_failure Text::Error::INVALID_CONFIGURED_PATTERN % pattern.inspect
      else
        say Text::Process::TEST_PATTERN_INSTRUCTIONS unless options[:non_interactive]
        ask_or_update.call(:test_pattern, Text::Prompt::TEST_PATTERN, Default::SUITE_TEST_PATTERN)
      end


      unless options[:non_interactive]
        say(Text::Process::SETUP_CI)
      end

      ask_or_update.call(:ci_pull_url, Text::Prompt::CI_PULL_URL, Tddium::Git.git_origin_url) 
      ask_or_update.call(:ci_push_url, Text::Prompt::CI_PUSH_URL, nil)
    end
  end
end
