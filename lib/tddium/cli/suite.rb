# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def current_suite_id
      branch = Tddium::Git.git_current_branch
      id = @api_config.fetch('branches', branch, 'id')
      return id
    end

    def current_suite_options
      branch = Tddium::Git.git_current_branch
      options = @api_config.fetch('branches', branch, 'options')
      return options
    end

    def current_suite_path
      "#{Api::Path::SUITES}/#{current_suite_id}"
    end

    def get_suites(params={})
      current_suites = call_api(:get, Api::Path::SUITES, params)
      current_suites ||= {}
      return current_suites['suites'] || []
    end

    def format_suite_details(suite)
      # Given an API response containing a "suite" key, compose a string with
      # important information about the suite
      details = ERB.new(Text::Status::SUITE_DETAILS).result(binding)
      details
    end

    def suite_for_current_branch?
      unless current_suite_id
        message = Text::Error::NO_SUITE_EXISTS % Tddium::Git.git_current_branch
        say message
      end
      message.nil?
    end

    def suite_resolve_name(options, params, default_suite_name)
      # XXX updates params
      existing_suite = nil
      use_existing_suite = false
      suite_name_resolved = false
      while !suite_name_resolved
        # Check to see if there is an existing suite
        current_suites = call_api(:get, Api::Path::SUITES, params)
        existing_suite = current_suites["suites"].first

        # Get the suite name
        current_suite_name = params[:repo_name]
        if existing_suite
          # Prompt for using existing suite (unless suite name is passed from command line) or entering new one
          params[:repo_name] = prompt(Text::Prompt::USE_EXISTING_SUITE % params[:branch], options[:name], current_suite_name)
          if options[:name] || params[:repo_name] == Text::Prompt::Response::YES
            # Use the existing suite, so assign the value back and exit the loop
            params[:repo_name] = current_suite_name
            use_existing_suite = true
            suite_name_resolved = true
          end
        elsif current_suite_name == default_suite_name
          # Prompt for using default suite name or entering new one
          params[:repo_name] = prompt(Text::Prompt::SUITE_NAME, options[:name], current_suite_name)
          suite_name_resolved = true if params[:repo_name] == default_suite_name
        else
          # Suite name does not exist yet and already prompted
          suite_name_resolved = true
        end
      end
      [use_existing_suite, existing_suite]
    end

    def update_suite(suite, options)
      params = {}
      prompt_suite_params(options, params, suite)

      ask_or_update = lambda do |key, text, default|
        params[key] = prompt(text, options[key], suite.fetch(key.to_s, default), options[:non_interactive])
      end

      ask_or_update.call(:campfire_room, Text::Prompt::CAMPFIRE_ROOM, '') 
      ask_or_update.call(:hipchat_room, Text::Prompt::HIPCHAT_ROOM, '') 

      call_api(:put, "#{Api::Path::SUITES}/#{suite['id']}", params)
      say Text::Process::UPDATED_SUITE
    end

    # Update the suite parameters from tddium.yml
    def update_suite_parameters!(current_suite)
      update_params = {}

      pattern = configured_test_pattern
      if pattern.is_a?(Array)
        pattern = pattern.join(",")
      end

      if pattern && current_suite["suite"]["test_pattern"] != pattern
        update_params[:test_pattern] = pattern
      end

      configured_ruby_version = @repo_config[:ruby_version]
      if configured_ruby_version && 
         configured_ruby_version != current_suite["suite"]["ruby_version"]
        update_params[:ruby_version] = configured_ruby_version
      end

      unless update_params.empty?
        call_api(:put, current_suite_path, update_params)
        if update_params[:test_pattern]
          say Text::Process::UPDATED_TEST_PATTERN % pattern
        end
        if update_params[:ruby_version]
          say Text::Process::UPDATED_RUBY_VERSION % configured_ruby_version
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

    def suite_auto_configure
      if current_suite_id then
        current_suite = call_api(:get, current_suite_path)["suite"]
      else
        default_suite_name = Tddium::Git.git_repo_name

        params = Hash.new
        params[:branch] = Tddium::Git.git_current_branch
        params[:repo_name] = default_suite_name

        current_suites = call_api(:get, Api::Path::SUITES, params)
        existing_suite = current_suites["suites"].first

        if existing_suite then
          current_suite = existing_suite
          say Text::Process::USING_EXISTING_SUITE % [params[:repo_name], params[:branch]]
        else
          #
          prompt_suite_params(options.merge({:non_interactive => true}), params)

          # Create new suite if it does not exist yet
          say Text::Process::CREATING_SUITE % [params[:repo_name], params[:branch]]

          new_suite = call_api(:post, Api::Path::SUITES, {:suite => params})
          current_suite = new_suite['suite']
        end

        # Save the created suite
        @api_config.set_suite(current_suite)
      end
      return current_suite
    end
  end
end
