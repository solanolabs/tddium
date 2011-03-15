=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require "rubygems"
require "thor"
require "json"
require "tddium_client"
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
#
#      tddium dev      # Enter "dev" mode, for single-test quick-turnaround debugging.
#      tddium stopdev  # Leave "dev" mode.
#
#      tddium clean    # Clean up test results, especially large objects like videos
#
#      tddium help     # Print this usage message

class Tddium < Thor
  include TddiumConstant

  desc "suite", "Register the suite for this project, or manage its settings"
  method_option :ssh_key, :type => :string, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  method_option :name, :type => :string, :default => nil
  method_option :environment, :type => :string, :default => nil
  def suite
    set_default_environment(options[:environment])
    return unless git_repo? && tddium_settings

    params = {}
    if current_suite_id
      call_api(:get, current_suite_path) do |api_response|
        # Get current values and prompt for updates
        current_ssh_key = api_response["suite"]["ssh_key"]
        ssh_file = options[:ssh_key] || ask(Text::Prompt::SSH_KEY % current_ssh_key[0, 30])
        if ssh_file.empty?
          params[:ssh_key] = current_ssh_key
        else
          params[:ssh_key] = File.open(File.expand_path(ssh_file)) {|file| file.read}
        end

        current_test_pattern = api_response["suite"]["test_pattern"]
        test_pattern = options[:test_pattern] || ask(Text::Prompt::TEST_PATTERN % current_test_pattern)
        params[:test_pattern] = test_pattern.empty? ? current_test_pattern : test_pattern

        # Update the current suite if it exists already
        call_api(:put, current_suite_path, {:suite => params}) do |api_response|
          say Text::Process::UPDATE_SUITE
        end
      end
    else
      # Inputs for new suite
      ssh_file = options[:ssh_key] || ask(Text::Prompt::SSH_KEY % Default::SSH_FILE)
      ssh_file = Default::SSH_FILE if ssh_file.empty?
      params[:ssh_key] = File.open(File.expand_path(ssh_file)) {|file| file.read}

      test_pattern = options[:test_pattern] || ask(Text::Prompt::TEST_PATTERN % Default::TEST_PATTERN)
      params[:test_pattern] = test_pattern.empty? ? Default::TEST_PATTERN : test_pattern

      default_suite_name = "#{File.basename(Dir.pwd)}/#{current_git_branch}"
      suite_name = options[:name] || ask(Text::Prompt::SUITE_NAME % default_suite_name)
      params[:suite_name] = suite_name.empty? ? default_suite_name : suite_name
      params[:ruby_version] = `ruby -v`.match(/^ruby ([\d\.]+)/)[1]

      # Create new suite if it does not exist yet
      call_api(:post, Api::Path::SUITES, {:suite => params}) do |api_response|
        # Manage git
        `git remote rm #{Git::REMOTE_NAME}`
        `git remote add #{Git::REMOTE_NAME} #{tddium_git_repo_uri(params[:suite_name])}`
        git_push

        # Save the created suite
        branches = tddium_settings["branches"] || {}
        branches.merge!({current_git_branch => api_response["suite"]["id"]})
        File.open(tddium_file_name, "w") do |file|
          file.write(tddium_settings.merge({"branches" => branches}).to_json)
        end
      end
    end
  end

  desc "spec", "Run the test suite"
  method_option :environment, :type => :string, :default => nil
  def spec
    set_default_environment(options[:environment])
    return unless git_repo? && tddium_settings && suite_for_current_branch?

    start_time = Time.now

    # Push the latest code to git
    git_push

    # Call the API to get the suite and its tests
    call_api(:get, current_suite_path) do |api_response|
      test_pattern = api_response["suite"]["test_pattern"]
      test_files = Dir.glob(test_pattern).collect {|file_path| {:test_name => file_path}}

      # Create a session
      call_api(:post, Api::Path::SESSIONS) do |api_response|
        session_id = api_response["session"]["id"]

        # Call the API to register the tests
        call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::REGISTER_TEST_EXECUTIONS}", {:suite_id => current_suite_id, :tests => test_files}) do |api_response|
          # Start the tests
          call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::START_TEST_EXECUTIONS}") do |api_response|
            tests_not_finished_yet = true
            finished_tests = {}
            test_statuses = Hash.new(0)
            api_call_error = nil

            say Text::Process::STARTING_TEST % test_files.size
            say Text::Process::TERMINATE_INSTRUCTION
            while tests_not_finished_yet && api_call_error.nil? do
              # Poll the API to check the status
              api_call_error = call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::TEST_EXECUTIONS}") do |api_response|
                # Catch Ctrl-C to interrupt the test
                Signal.trap(:INT) do
                  say Text::Process::INTERRUPT
                  say Text::Process::CHECK_TEST_STATUS
                  tests_not_finished_yet = false
                end

                # Print out the progress of running tests
                api_response["tests"].each do |test_name, result_params|
                  test_status = result_params["status"]
                  if result_params["end_time"] && !finished_tests[test_name]
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
                finished_tests.size == api_response["tests"].size ? tests_not_finished_yet = false : sleep(Default::SLEEP_TIME_BETWEEN_POLLS)
              end
            end

            # Print out the result
            say Text::Process::FINISHED_TEST % (Time.now - start_time)
            say "#{finished_tests.size} examples, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending"
            say Text::Process::CHECK_TEST_REPORT % api_response["report"]
          end
        end
      end
    end
  end

  desc "status", "Display information about this suite, and any open dev sessions"
  method_option :environment, :type => :string, :default => nil
  def status
    set_default_environment(options[:environment])
    return unless git_repo? && tddium_settings && suite_for_current_branch?

    call_api(:get, Api::Path::SUITES) do |api_response|
      if api_response["suites"].size == 0
        say "You currently do not have any suite"
      else
        say "Your suites: #{api_response["suites"].collect {|suite| suite["suite_name"]}.join(", ")}"

        if current_suite = api_response["suites"].detect {|suite| suite["id"] == current_suite_id}
          say "====="
          say "Your current suite: #{current_suite["suite_name"]}}"

          displayed_attributes = %w{suite_name ssh_key test_pattern ruby_version}
          displayed_attributes.each do |attr|
            say("  #{attr.gsub("_", " ").capitalize}: #{current_suite[attr]}") if current_suite[attr]
          end

          call_api(:get, Api::Path::SESSIONS, {:active => true}) do |api_response|
            say "====="
            if api_response["sessions"].size == 0
              say "There is no active session"
            else
              say "Your active sessions:"
              api_response["sessions"].each do |session|
                say("  Session #{session["id"]}:")
                displayed_attributes = %w{start_time end_time suite result}
                displayed_attributes.each do |attr|
                  say("    #{attr.gsub("_", " ").capitalize}: #{session[attr]}") if session[attr]
                end
              end
            end
          end

          call_api(:get, Api::Path::SESSIONS, {:active => false, :order => "date", :limit => 10}) do |api_response|
            say "====="
            if api_response["sessions"].size == 0
              say "There is no session"
            else
              say "Your latest sessions:"
              api_response["sessions"].each do |session|
                say("  Session #{session["id"]}:")
                displayed_attributes = %w{start_time end_time suite result}
                displayed_attributes.each do |attr|
                  say("    #{attr.gsub("_", " ").capitalize}: #{session[attr]}") if session[attr]
                end
              end
            end
          end
        else
          say "Your current suite is unavailable"
        end
      end

    end
  end

  private

  def git_push
    `git push #{Git::REMOTE_NAME} #{current_git_branch}`
  end

  def call_api(method, api_path, params = {}, &block)
    api_key =  tddium_settings(false)["api_key"] if tddium_settings(false)
    response = tddium_client.call_api(method, api_path, params, api_key, &block)
    say response[1] if response
    response
  end

  def tddium_git_repo_uri(suite_name)
    repo_name = suite_name.split("/").first
    git_uri = URI.parse("")
    git_uri.host = Git::HOST
    git_uri.scheme = Git::SCHEME
    git_uri.userinfo = "git"
    git_uri.path = "#{Git::ABSOLUTE_PATH}/#{repo_name}"
    git_uri.to_s
  end

  def current_git_branch
    @current_git_branch ||= File.basename(`git symbolic-ref HEAD`.gsub("\n", ""))
  end

  def current_suite_id
    tddium_settings["branches"][current_git_branch] if tddium_settings["branches"]
  end

  def current_suite_path
    "#{Api::Path::SUITES}/#{current_suite_id}"
  end

  def suite_for_current_branch?
    unless current_suite_id
      message = Text::Error::NO_SUITE_EXISTS % current_git_branch
      say message
    end
    message.nil?
  end

  def tddium_file_name
    extension = ".#{environment}" unless environment == :production
    ".tddium#{extension}"
  end

  def tddium_settings(fail_with_message = true)
    unless @tddium_settings
      if File.exists?(tddium_file_name)
        tddium_config = File.open(tddium_file_name) do |file|
          file.read
        end
        @tddium_settings = JSON.parse(tddium_config) rescue nil
        say (Text::Error::INVALID_TDDIUM_FILE % environment) if @tddium_settings.nil? && fail_with_message
      else
        say Text::Error::NOT_INITIALIZED if fail_with_message
      end
    end
    @tddium_settings
  end

  def git_repo?
    unless File.exists?(".git")
      message = Text::Error::GIT_NOT_INITIALIZED
      say message
    end
    message.nil?
  end

  def set_default_environment(env)
    if env.nil?
      tddium_client.environment = :development
      tddium_client.environment = :production unless File.exists?(tddium_file_name)
    else
      tddium_client.environment = env.to_sym
    end
  end

  def environment
    tddium_client.environment
  end

  def tddium_client
    @tddium_client ||= TddiumClient.new
  end
end
