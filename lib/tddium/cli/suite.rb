# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def update_suite(suite, options)
      params = {}
      prompt_suite_params(options, params, suite)

      ask_or_update = lambda do |key, text, default|
        params[key] = prompt(text, options[key], suite.fetch(key.to_s, default), options[:non_interactive])
      end

      ask_or_update.call(:campfire_room, Text::Prompt::CAMPFIRE_ROOM, '')
      ask_or_update.call(:hipchat_room, Text::Prompt::HIPCHAT_ROOM, '')

      @tddium_api.update_suite(suite['id'], params)
      say Text::Process::UPDATED_SUITE
    end

    def suite_auto_configure
      # Did the user set a configuration option on the command line?
      # If so, auto-configure a new suite and re-configure an existing one
      user_config = options.member?(:tool)

      current_suite_id = @tddium_api.current_suite_id
      if current_suite_id && !user_config then
        current_suite = @tddium_api.get_suite_by_id(current_suite_id)
      else
        params = Hash.new
        params[:branch] = @scm.current_branch
        params[:repo_url] = @scm.origin_url
        params[:repo_name] = @scm.repo_name
        params[:scm] = @scm.scm_name
        if options[:account] && !params.member?(:account_id) then
          account_id = @tddium_api.get_account_id(options[:account])
          params[:account_id] = account_id if account_id
        end

        tool_cli_populate(options, params)
        defaults = {}

        prompt_suite_params(options.merge({:non_interactive => true}), params, defaults)

        # Create new suite if it does not exist yet
        say Text::Process::CREATING_SUITE % [params[:repo_name], params[:branch]]

        current_suite = @tddium_api.create_suite(params)

        # Save the created suite
        @api_config.set_suite(current_suite)
        @api_config.write_config
      end
      return current_suite
    end

    def format_suite_details(suite)
      # Given an API response containing a "suite" key, compose a string with
      # important information about the suite
      tddium_deploy_key_file_name = @api_config.tddium_deploy_key_file_name
      details = ERB.new(Text::Status::SUITE_DETAILS).result(binding)
      details
    end

    def suite_for_current_branch?
      return true if @tddium_api.current_suite_id
      say Text::Error::NO_SUITE_EXISTS % @scm.current_branch
      false
    end

    def suite_for_default_branch?
      return true if @tddium_api.default_suite_id
      say Text::Error::NO_SUITE_EXISTS % @scm.default_branch
      false
    end

    # Update the suite parameters from solano.yml
    def update_suite_parameters!(current_suite, session_id=nil)
      update_params = {}

      update_params[:session_id] = session_id if session_id

      pattern = configured_test_pattern
      if pattern.is_a?(Array)
        pattern = pattern.join(",")
      end
      if pattern && current_suite["test_pattern"] != pattern then
        update_params[:test_pattern] = pattern
      end

      exclude_pattern = configured_test_exclude_pattern
      if exclude_pattern.is_a?(Array)
        exclude_pattern = exclude_pattern.join(",")
      end
      if exclude_pattern && current_suite["test_exclude_pattern"] != exclude_pattern then
        update_params[:test_exclude_pattern] = exclude_pattern
      end

      ruby_version = sniff_ruby_version
      if ruby_version && ruby_version != current_suite["ruby_version"] then
        update_params[:ruby_version] = ruby_version
      end

      bundler_version = @repo_config["bundler_version"]
      if bundler_version && bundler_version != current_suite["bundler_version"] then
        update_params[:bundler_version] = bundler_version
      end

      test_configs = @repo_config["tests"] || []
      if test_configs != (current_suite['test_configs'] || []) then
        if test_configs != 'disable' && !test_configs.is_a?(Array) then
          warn(Text::Warning::TEST_CONFIGS_MUST_BE_LIST)
          test_configs = []
        end
        update_params[:test_configs] = test_configs
      end

      %w(golang java leiningen nodejs php python scala).each do |lang|
        config_name = "#{lang}_config"
        lang_config = @repo_config[lang] || {}
        current_lang_config = current_suite[config_name] || {}
        if lang_config != (current_suite[config_name] || {}) then
          update_params[lang.to_sym] = lang_config
        end
      end

      if !update_params.empty? then
        @tddium_api.update_suite(@tddium_api.current_suite_id, update_params)
        if update_params[:test_pattern]
          say Text::Process::UPDATED_TEST_PATTERN % pattern
        end
        if update_params[:test_exclude_pattern]
          say Text::Process::UPDATED_TEST_EXCLUDE_PATTERN % exclude_pattern
        end
        if update_params[:ruby_version]
          say Text::Process::UPDATED_RUBY_VERSION % ruby_version
        end
        if update_params[:bundler_version]
          say Text::Process::UPDATED_BUNDLER_VERSION % bundler_version
        end
        if update_params[:test_configs]
          say Text::Process::UPDATED_TEST_CONFIGS % YAML.dump(test_configs)
          say "(was:\n#{YAML.dump(current_suite['test_configs'])})\n"
        end
        if update_params[:python_config]
          say Text::Process::UPDATED_PYTHON_CONFIG % YAML.dump(python_config)
        end
        if update_params[:golang_config]
          say Text::Process::UPDATED_PYTHON_CONFIG % YAML.dump(golang_config)
        end
        if update_params[:java_config]
          say Text::Process::UPDATED_PYTHON_CONFIG % YAML.dump(java_config)
        end
      end
    end

    def suite_remembered_option(options, key, default, &block)
      remembered = false
      if options[key] != default
        result = options[key]
      elsif remembered = current_suite_options[key.to_s]
        result = remembered
        remembered = true
      else
        result = default
      end

      if result then
        msg = Text::Process::USING_SPEC_OPTION[key] % result
        msg +=  Text::Process::REMEMBERED if remembered
        msg += "\n"
        say msg
        yield result if block_given?
      end
      result
    end
  end
end
