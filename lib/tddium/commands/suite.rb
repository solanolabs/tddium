=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium

  desc "suite", "Register the current repo/branch, view/edit CI repos & deploy keys"
  method_option :edit, :type => :boolean, :default => false
  method_option :name, :type => :string, :default => nil
  method_option :ci_pull_url, :type => :string, :default => nil
  method_option :ci_push_url, :type => :string, :default => nil
  method_option :campfire_subdomain, :type=> :string, :default => nil
  method_option :campfire_room, :type=> :string, :default => nil
  method_option :campfire_token, :type=> :string, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  def suite
    set_default_environment
    git_version_ok
    exit_failure unless tddium_settings && git_repo?

    params = {}
    begin
      if current_suite_id
        current_suite = call_api(:get, current_suite_path)["suite"]

        if options[:edit]
          update_suite(current_suite, options)
        else
          say Text::Process::EXISTING_SUITE % format_suite_details(current_suite)
        end
      else
        params[:branch] = current_git_branch
        default_suite_name = File.basename(Dir.pwd)
        params[:repo_name] = options[:name] || default_suite_name

        say Text::Process::NO_CONFIGURED_SUITE % [params[:repo_name], params[:branch]]

        use_existing_suite, existing_suite = resolve_suite_name(options, params, default_suite_name)

        if use_existing_suite
          # Write to file and exit when using the existing suite
          write_suite(existing_suite)
          say Text::Status::USING_SUITE % format_suite_details(existing_suite)
          return
        end

        prompt_suite_params(options, params)

        params.each do |k,v|
          params.delete(k) if v == 'disable'
        end

        # Create new suite if it does not exist yet
        say Text::Process::CREATING_SUITE % [params[:repo_name], params[:branch]]
        new_suite = call_api(:post, Api::Path::SUITES, {:suite => params})
        # Save the created suite
        write_suite(new_suite["suite"])

        say Text::Process::CREATED_SUITE % format_suite_details(new_suite["suite"])
      end
    rescue TddiumClient::Error::Base
      exit_failure
    end
  end

  private

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

  def configured_test_pattern
    pattern = tddium_config[:test_pattern] || tddium_config['test_pattern']
    
    return nil if pattern.nil? || pattern.empty?

    return pattern
  end

  def prompt_suite_params(options, params, current={})
    say Text::Process::DETECTED_BRANCH % params[:branch] if params[:branch]
    params[:ruby_version] = tool_version(:ruby)
    params[:bundler_version] = tool_version(:bundle)
    params[:rubygems_version] = tool_version(:gem)

    ask_or_update = lambda do |key, text, default|
      params[key] = prompt(text, options[key], current.fetch(key.to_s, default))
    end

    pattern = configured_test_pattern

    if pattern.is_a?(Array)
      say Text::Process::CONFIGURED_PATTERN % pattern.map{|p| " - #{p}"}.join("\n")
      params[:test_pattern] = pattern.join(",")
    elsif pattern
      exit_failure Text::Error::INVALID_CONFIGURED_PATTERN % pattern.inspect
    else
      say Text::Process::TEST_PATTERN_INSTRUCTIONS
      ask_or_update.call(:test_pattern, Text::Prompt::TEST_PATTERN, Default::SUITE_TEST_PATTERN)
    end


    if current.size > 0 && current['ci_pull_url']
      say(Text::Process::SETUP_CI_EDIT)
    else
      say(Text::Process::SETUP_CI_FIRST_TIME)
    end

    ask_or_update.call(:ci_pull_url, Text::Prompt::CI_PULL_URL, git_origin_url) 
    ask_or_update.call(:ci_push_url, Text::Prompt::CI_PUSH_URL, nil)

    if current.size > 0 && current['campfire_room']
      say(Text::Process::SETUP_CAMPFIRE_EDIT)
    else
      say(Text::Process::SETUP_CAMPFIRE_FIRST_TIME)
    end

    subdomain = ask_or_update.call(:campfire_subdomain, Text::Prompt::CAMPFIRE_SUBDOMAIN, nil)
    if !subdomain.nil? && subdomain != 'disable' then
      ask_or_update.call(:campfire_token, Text::Prompt::CAMPFIRE_TOKEN, nil)
      ask_or_update.call(:campfire_room, Text::Prompt::CAMPFIRE_ROOM, nil)
    end
  end

  def update_suite(suite, options)
    params = {}
    prompt_suite_params(options, params, suite)
    call_api(:put, "#{Api::Path::SUITES}/#{suite['id']}", params)
    say Text::Process::UPDATED_SUITE
  end

  def resolve_suite_name(options, params, default_suite_name)
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

end
