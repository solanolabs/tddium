=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require "rubygems"
require "thor"
require "highline/import"
require "json"
require "tddium_client"
require "base64"
require File.expand_path("../tddium/constant", __FILE__)

#      Usage:
#
#      tddium suite    # Register the suite for this rails app, or manage its settings
#      tddium spec     # Run the test suite
#      tddium status   # Display information about this suite, and any open dev sessions
#
#      tddium login    # Log your unix user in to a tddium account
#      tddium logout   # Log out
#
#      tddium account  # View/Manage account information
#      tddium account:password # Change password
#
#      tddium help     # Print this usage message

class Tddium < Thor
  include TddiumConstant

  desc "account", "View/Manage account information"
  method_option :environment, :type => :string, :default => nil
  method_option :email, :type => :string, :default => nil
  method_option :password, :type => :string, :default => nil
  method_option :ssh_key_file, :type => :string, :default => nil
  def account
    set_default_environment(options[:environment])
    if user_details = user_logged_in?
      # User is already logged in, so just display the info
      show_user_details(user_details)
    elsif heroku_config = get_heroku_config
      # User has logged in to heroku, and TDDIUM environment variables are
      # present
      handle_heroku_user(heroku_config)
    else
      params = get_user_credentials(options.merge(:invited => true))

      # Prompt for the password confirmation if password is not from command line
      unless options[:password]
        password_confirmation = HighLine.ask(Text::Prompt::PASSWORD_CONFIRMATION) { |q| q.echo = "*" }
        unless password_confirmation == params[:password]
          say Text::Process::PASSWORD_CONFIRMATION_INCORRECT
          return
        end
      end

      # Prompt for ssh-key file
      ssh_file = prompt(Text::Prompt::SSH_KEY, options[:ssh_key_file], Default::SSH_FILE)
      params[:user_git_pubkey] = File.open(File.expand_path(ssh_file)) {|file| file.read}

      # Prompt for accepting license
      content =  File.open(File.join(File.dirname(__FILE__), "..", License::FILE_NAME)) do |file|
        file.read
      end
      say content
      license_accepted = ask(Text::Prompt::LICENSE_AGREEMENT)
      return unless license_accepted.downcase == Text::Prompt::Response::AGREE_TO_LICENSE.downcase

      begin
        new_user = call_api(:post, Api::Path::USERS, {:user => params}, false, false)
        write_api_key(new_user["user"]["api_key"])
        say Text::Process::ACCOUNT_CREATED % [new_user["user"]["email"], new_user["user"]["recurly_url"]]
      rescue TddiumClient::Error::API => e
        say((e.status == Api::ErrorCode::INVALID_INVITATION) ? Text::Error::INVALID_INVITATION : e.message)
      rescue TddiumClient::Error::Base => e
        say e.message
      end
    end
  end

  desc "password", "Change password"
  method_option :environment, :type => :string, :default => nil
  def password
    set_default_environment(options[:environment])
    return unless tddium_settings
    user_details = user_logged_in?
    return unless user_details
    
    params = {}
    params[:current_password] = HighLine.ask(Text::Prompt::CURRENT_PASSWORD) { |q| q.echo = "*" }
    params[:password] = HighLine.ask(Text::Prompt::NEW_PASSWORD) { |q| q.echo = "*" }
    params[:password_confirmation] = HighLine.ask(Text::Prompt::PASSWORD_CONFIRMATION) { |q| q.echo = "*" }

    begin
      user_id = user_details["user"]["id"]
      result = call_api(:put, "#{Api::Path::USERS}/#{user_id}/", {:user=>params},
                        tddium_settings["api_key"], false)
      say Text::Process::PASSWORD_CHANGED
    rescue TddiumClient::Error::API => e
      say Text::Error::PASSWORD_ERROR % e.explanation
    rescue TddiumClient::Error::Base => e
      say e.message
    end
  end

  desc "login", "Log in to tddium using your email address and password"
  method_option :environment, :type => :string, :default => nil
  method_option :email, :type => :string, :default => nil
  method_option :password, :type => :string, :default => nil
  def login
    set_default_environment(options[:environment])
    if user_logged_in?
      say Text::Process::ALREADY_LOGGED_IN
    else
      say Text::Process::LOGGED_IN_SUCCESSFULLY if login_user(:params => get_user_credentials(options), :show_error => true)
    end
  end

  desc "logout", "Log out of tddium"
  method_option :environment, :type => :string, :default => nil
  def logout
    set_default_environment(options[:environment])
    FileUtils.rm(tddium_file_name) if File.exists?(tddium_file_name)
    say Text::Process::LOGGED_OUT_SUCCESSFULLY
  end

  desc "spec", "Run the test suite"
  method_option :environment, :type => :string, :default => nil
  method_option :user_data_file, :type => :string, :default => nil
  method_option :max_parallelism, :type => :numeric, :default => nil
  method_option :test_pattern, :type => :string, :default => Default::TEST_PATTERN
  def spec
    set_default_environment(options[:environment])
    exit_failure unless git_repo? && tddium_settings && suite_for_current_branch?

    test_execution_params = {}

    # Set the user data for spec
    if user_data_file_path = options[:user_data_file] || current_suite_options["user_data_file"]
      say Text::Process::USING_PREVIOUS_USER_DATA_FILE % user_data_file_path if user_data_file_path == current_suite_options["user_data_file"]

      if File.exists?(user_data_file_path)
        user_data = File.open(user_data_file_path) { |file| file.read }
        test_execution_params[:user_data_text] = Base64.encode64(user_data)
        test_execution_params[:user_data_filename] = File.basename(user_data_file_path)
      else
        exit_failure Text::Error::NO_USER_DATA_FILE % user_data_file_path
      end
    end

    # Set max parallelism param
    if max_parallelism = options[:max_parallelism] || current_suite_options["max_parallelism"]
      say Text::Process::USING_PREVIOUS_MAX_PARALLELISM % max_parallelism if max_parallelism == current_suite_options["max_parallelism"]
      test_execution_params[:max_parallelism] = max_parallelism
    end
    
    # Set test_pattern param
    if current_suite_options["test_pattern"]
      test_pattern = current_suite_options["test_pattern"]
      say Text::Process::USING_PREVIOUS_TEST_PATTERN % test_pattern if options[:test_pattern] == current_suite_options["test_pattern"]
    else
      test_pattern = options[:test_pattern]
    end

    start_time = Time.now

    # Call the API to get the suite and its tests
    begin
      suite_details = call_api(:get, current_suite_path)

      # Push the latest code to git
      exit_failure unless update_git_remote_and_push(suite_details)

      # Get a list of files to be tested
      test_files = Dir.glob(test_pattern).collect {|file_path| {:test_name => file_path}}

      if test_files.empty?
        exit_failure Text::Error::NO_MATCHING_FILES % test_pattern
      end

      # Create a session
      new_session = call_api(:post, Api::Path::SESSIONS)
      session_id = new_session["session"]["id"]

      # Register the tests
      call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::REGISTER_TEST_EXECUTIONS}", {:suite_id => current_suite_id, :tests => test_files})

      # Start the tests
      start_test_executions = call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::START_TEST_EXECUTIONS}", test_execution_params)
      tests_not_finished_yet = true
      finished_tests = {}
      test_statuses = Hash.new(0)

      say Text::Process::STARTING_TEST % test_files.size
      say Text::Process::CHECK_TEST_REPORT % start_test_executions["report"]
      say Text::Process::TERMINATE_INSTRUCTION
      while tests_not_finished_yet do
        # Poll the API to check the status
        current_test_executions = call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::TEST_EXECUTIONS}")

        # Catch Ctrl-C to interrupt the test
        Signal.trap(:INT) do
          say Text::Process::INTERRUPT
          say Text::Process::CHECK_TEST_STATUS
          tests_not_finished_yet = false
        end

        # Print out the progress of running tests
        current_test_executions["tests"].each do |test_name, result_params|
          test_status = result_params["status"]
          if result_params["finished"] && !finished_tests[test_name]
            message = case test_status
                        when "passed" then [".", :green, false]
                        when "failed" then ["F", :red, false]
                        when "error" then ["E", nil, false]
                        when "pending" then ["*", :yellow, false]
                      end
            finished_tests[test_name] = test_status
            test_statuses[test_status] += 1
            say *message
          end
        end

        # If all tests finished, exit the loop else sleep
        if finished_tests.size == current_test_executions["tests"].size
          tests_not_finished_yet = false
        else
          sleep(Default::SLEEP_TIME_BETWEEN_POLLS)
        end
      end

      # Print out the result
      say ""
      say Text::Process::FINISHED_TEST % (Time.now - start_time)
      say "#{finished_tests.size} tests, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending"

      # Save the spec options
      write_suite(current_suite_id, {"user_data_file" => user_data_file_path,
                                     "max_parallelism" => max_parallelism,
                                     "test_pattern" => test_pattern})

      exit_failure if test_statuses["failed"] > 0 || test_statuses["errors"] > 0
    rescue TddiumClient::Error::Base
    end
  end

  desc "status", "Display information about this suite, and any open dev sessions"
  method_option :environment, :type => :string, :default => nil
  def status
    set_default_environment(options[:environment])
    return unless git_repo? && tddium_settings && suite_for_current_branch?

    begin
      current_suites = call_api(:get, Api::Path::SUITES)
      if current_suites["suites"].size == 0
        say Text::Status::NO_SUITE
      else
        say Text::Status::ALL_SUITES % current_suites["suites"].collect {|suite| suite["repo_name"]}.join(", ")

        if current_suite = current_suites["suites"].detect {|suite| suite["id"] == current_suite_id}
          say Text::Status::SEPARATOR
          say Text::Status::CURRENT_SUITE % current_suite["repo_name"]

          display_attributes(DisplayedAttributes::SUITE, current_suite)

          show_session_details({:active => true}, Text::Status::NO_ACTIVE_SESSION, Text::Status::ACTIVE_SESSIONS)
          show_session_details({:active => false, :order => "date", :limit => 10}, Text::Status::NO_INACTIVE_SESSION, Text::Status::INACTIVE_SESSIONS)
        else
          say Text::Status::CURRENT_SUITE_UNAVAILABLE
        end
      end

      account_usage = call_api(:get, Api::Path::ACCOUNT_USAGE)
      say account_usage["usage"]
    rescue TddiumClient::Error::Base
    end
  end

  desc "suite", "Register the suite for this project, or manage its settings"
  method_option :name, :type => :string, :default => nil
  method_option :environment, :type => :string, :default => nil
  def suite
    set_default_environment(options[:environment])
    return unless git_repo? && tddium_settings

    params = {}
    begin
      if current_suite_id
        current_suite = call_api(:get, current_suite_path)["suite"]

        say Text::Process::EXISTING_SUITE % "#{current_suite["repo_name"]}/#{current_suite["branch"]}"
      else
        params[:branch] = current_git_branch
        default_suite_name = File.basename(Dir.pwd)
        params[:repo_name] = options[:name] || default_suite_name

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
            params[:repo_name] = prompt(Text::Prompt::USE_EXISTING_SUITE, options[:name], current_suite_name)
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

        if use_existing_suite
          # Write to file and exit when using the existing suite
          write_suite(existing_suite["id"])
          say Text::Status::USING_SUITE % [existing_suite["repo_name"], existing_suite["branch"]]
          return
        end

        params[:ruby_version] = dependency_version(:ruby)
        params[:bundler_version] = dependency_version(:bundle)
        params[:rubygems_version] = dependency_version(:gem)


        # Create new suite if it does not exist yet
        say Text::Process::CREATING_SUITE % params[:repo_name]
        new_suite = call_api(:post, Api::Path::SUITES, {:suite => params})
        # Save the created suite
        write_suite(new_suite["suite"]["id"])

        # Manage git
        update_git_remote_and_push(new_suite)
      end
    rescue TddiumClient::Error::Base
    end
  end

  private

  def call_api(method, api_path, params = {}, api_key = nil, show_error = true)
    api_key =  tddium_settings(:fail_with_message => false)["api_key"] if tddium_settings(:fail_with_message => false) && api_key != false
    begin
      result = tddium_client.call_api(method, api_path, params, api_key)
    rescue TddiumClient::Error::Base => e
      say e.message if show_error
      raise e
    end
    result
  end

  def current_git_branch
    @current_git_branch ||= File.basename(`git symbolic-ref HEAD`.gsub("\n", ""))
  end

  def current_suite_id
    tddium_settings["branches"][current_git_branch]["id"] if tddium_settings["branches"] && tddium_settings["branches"][current_git_branch]
  end

  def current_suite_options
    if tddium_settings["branches"] && tddium_settings["branches"][current_git_branch]
      tddium_settings["branches"][current_git_branch]["options"]
    end || {}
  end

  def current_suite_path
    "#{Api::Path::SUITES}/#{current_suite_id}"
  end

  def dependency_version(command)
    `#{command} -v`.match(Dependency::VERSION_REGEXP)[1]
  end

  def display_attributes(names_to_display, attributes)
    names_to_display.each do |attr|
      say Text::Status::ATTRIBUTE_DETAIL % [attr.gsub("_", " ").capitalize, attributes[attr]] if attributes[attr]
    end
  end

  def environment
    tddium_client.environment.to_sym
  end

  def exit_failure(msg='')
    abort msg
  end

  def get_user
    call_api(:get, Api::Path::USERS, {}, nil, false) rescue nil
  end

  def get_user_credentials(options = {})
    params = {}
    # prompt for email/invitation and password
    if options[:invited]
      params[:invitation_token] = options[:invitation_token] || ask(Text::Prompt::INVITATION_TOKEN)
    else
      params[:email] = options[:email] || ask(Text::Prompt::EMAIL)
    end
    params[:password] = options[:password] || HighLine.ask(Text::Prompt::PASSWORD) { |q| q.echo = "*" }
    params
  end

  def git_push
    system("git push -f #{Git::REMOTE_NAME} #{current_git_branch}")
  end

  def git_repo?
    unless File.exists?(".git")
      message = Text::Error::GIT_NOT_INITIALIZED
      say message
    end
    message.nil?
  end

  def login_user(options = {})
    # POST (email, password) to /users/sign_in to retrieve an API key
    begin
      login_result = call_api(:post, Api::Path::SIGN_IN, {:user => options[:params]}, false, options[:show_error])
      # On success, write the API key to "~/.tddium.<environment>"
      write_api_key(login_result["api_key"])
    rescue TddiumClient::Error::Base
    end
    login_result
  end

  def prompt(text, current_value, default_value)
    value = current_value || ask(text % default_value)
    value.empty? ? default_value : value
  end

  def set_default_environment(env)
    if env.nil?
      tddium_client.environment = :development
      tddium_client.environment = :production unless File.exists?(tddium_file_name)
    else
      tddium_client.environment = env.to_sym
    end
  end

  def show_session_details(params, no_session_prompt, all_session_prompt)
    begin
      current_sessions = call_api(:get, Api::Path::SESSIONS, params)
      say Text::Status::SEPARATOR
      if current_sessions["sessions"].size == 0
        say no_session_prompt
      else
        say all_session_prompt
        current_sessions["sessions"].each do |session|
          session_id = session.delete("id")
          say Text::Status::SESSION_TITLE % session_id
          display_attributes(DisplayedAttributes::TEST_EXECUTION, session)
        end
      end
    rescue TddiumClient::Error::Base
    end
  end

  def show_user_details(api_response)
    # Given the user is logged in, she should be able to use "tddium account" to display information about her account:
    # Email address
    # Account creation date
    say api_response["user"]["email"]
    say api_response["user"]["created_at"]
    say api_response["user"]["recurly_url"]
  end

  def suite_for_current_branch?
    unless current_suite_id
      message = Text::Error::NO_SUITE_EXISTS % current_git_branch
      say message
    end
    message.nil?
  end

  def tddium_client
    @tddium_client ||= TddiumClient::Client.new
  end

  def tddium_file_name
    extension = ".#{environment}" unless environment == :production
    ".tddium#{extension}"
  end

  def tddium_settings(options = {})
    options[:fail_with_message] = true unless options[:fail_with_message] == false
    if @tddium_settings.nil? || options[:force_reload]
      if File.exists?(tddium_file_name)
        tddium_config = File.open(tddium_file_name) do |file|
          file.read
        end
        @tddium_settings = JSON.parse(tddium_config) rescue nil
        say (Text::Error::INVALID_TDDIUM_FILE % environment) if @tddium_settings.nil? && options[:fail_with_message]
      else
        say Text::Error::NOT_INITIALIZED if options[:fail_with_message]
      end
    end
    @tddium_settings
  end

  def update_git_remote_and_push(suite_details)
    git_repo_uri = suite_details["suite"]["git_repo_uri"]
    unless `git remote show -n #{Git::REMOTE_NAME}` =~ /#{git_repo_uri}/
      `git remote rm #{Git::REMOTE_NAME} > /dev/null 2>&1`
      `git remote add #{Git::REMOTE_NAME} #{git_repo_uri}`
    end
    git_push
  end

  def user_logged_in?(active = true, message = false)
    result = tddium_settings(:fail_with_message => message) && tddium_settings["api_key"]
    (result && active) ? get_user : result
  end

  def write_api_key(api_key)
    settings = tddium_settings(:fail_with_message => false) || {}
    File.open(tddium_file_name, "w") do |file|
      file.write(settings.merge({"api_key" => api_key}).to_json)
    end
    write_tddium_to_gitignore
  end

  def write_suite(suite_id, options = {})
    branches = tddium_settings["branches"] || {}
    branches.merge!({current_git_branch => {"id" => suite_id, "options" => options}})
    File.open(tddium_file_name, "w") do |file|
      file.write(tddium_settings.merge({"branches" => branches}).to_json)
    end
    write_tddium_to_gitignore
  end

  def write_tddium_to_gitignore
    content = File.exists?(Git::GITIGNORE) ? File.read(Git::GITIGNORE) : ''
    unless content.include?("#{tddium_file_name}\n")
      File.open(Git::GITIGNORE, "a") do |file|
        file.write("#{tddium_file_name}\n")
      end
    end
  end
end
