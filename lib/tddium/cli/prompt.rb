# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

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
      params[:ruby_version] ||= tool_version(:ruby)
      params[:bundler_version] ||= normalize_bundler_version(tool_version(:bundle))
      params[:rubygems_version] ||= tool_version(:gem)

      ask_or_update = lambda do |key, text, default|
        params[key] = prompt(text, options[key], current.fetch(key.to_s, default), options[:non_interactive])
      end

      # If we already have a suite, it already has an account, so no need to
      # figure it out here.
      unless current['account_id']
        # Find an account id. Strategy:
        # 1. Use a command line option, if specified.
        # 2. If the user has only one account, use that.
        # 3. If the user has existing suites with the same repo, and they are
        # all in the same account, prompt with that as a default.
        # 4. Prompt.
        # IF we're not allowed to prompt and have no default, fail.
        accounts = user_details["participating_accounts"]
        account_name = if options[:account]
          say Text::Process::USING_ACCOUNT_FROM_FLAG % options[:account]
          options[:account]
        elsif accounts.length == 1
          say Text::Process::USING_ACCOUNT % accounts.first["account"]
          accounts.first["account"]
        else
          # Get all of this user's suites with this repo.
          repo_suites = @tddium_api.get_suites(:repo_url => params[:repo_url])
          acct_ids = repo_suites.map{|s| s['account']}.uniq
          default = acct_ids.length == 1 ? acct_ids.first : nil

          if not options[:non_interactive] or default.nil?
            say "You are a member of these organizations:"
            accounts.each do |account|
              say "  " + account['account']
            end
          end

          msg = default.nil? ? Text::Prompt::ACCOUNT : Text::Prompt::ACCOUNT_DEFAULT
          prompt(msg, nil, default, options[:non_interactive])
        end

        if account_name.nil?
          exit_failure (options[:non_interactive] ?
                        Text::Error::MISSING_ACCOUNT_OPTION :
                        Text::Error::MISSING_ACCOUNT)
        end
        account = accounts.select{|a| a['account'] == account_name}.first
        if account.nil?
          exit_failure Text::Error::NOT_IN_ACCOUNT % account_name
        end

        #say Text::Process::USING_ACCOUNT % account_name
        params[:account_id] = account["account_id"].to_s
      end

      pattern = configured_test_pattern
      cfn = @repo_config.config_filename

      if pattern.is_a?(Array)
        say Text::Process::CONFIGURED_PATTERN % [cfn, pattern.map{|p| " - #{p}"}.join("\n"), cfn]
        params[:test_pattern] = pattern.join(",")
      elsif pattern
        if pattern == 'none' then
          params[:test_pattern] = []
        else
          exit_failure Text::Error::INVALID_CONFIGURED_PATTERN % [cfn, cfn, pattern.inspect, cfn]
        end
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
