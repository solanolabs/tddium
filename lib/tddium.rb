=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require "rubygems"
require "thor"
require "httparty"
require "json"

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
  API_HOST = "http://api.tddium.com"
  API_VERSION = "1"
  SUITES_PATH = "suites"
  SESSIONS_PATH = "sessions"
  TEST_EXECUTIONS_PATH = "test_executions"
  REGISTER_TEST_EXECUTIONS_PATH = "#{TEST_EXECUTIONS_PATH}/register"
  START_TEST_EXECUTIONS_PATH = "#{TEST_EXECUTIONS_PATH}/start"
  REPORT_TEST_EXECUTIONS_PATH = "#{TEST_EXECUTIONS_PATH}/report"
  GIT_REMOTE_NAME = "tddium"
  GIT_REMOTE_SCHEME = "ssh"
  GIT_REMOTE_USER = "git"
  GIT_REMOTE_ABSOLUTE_PATH = "/home/git/repo"

  desc "suite", "Register the suite for this rails app, or manage its settings"
  method_option :ssh_key, :type => :string, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  method_option :name, :type => :string, :default => nil
  def suite
    # Require git initialization
    unless File.exists?(".git")
      say "git repo must be initialized. Try 'git init'."
      return
    end

    # Inputs for API call
    params = {}

    default_ssh_file = "~/.ssh/id_rsa.pub"
    ssh_file = options[:ssh_key] || ask("Enter your ssh key or press 'Return'. Using #{default_ssh_file} by default:")
    ssh_file = default_ssh_file if ssh_file.empty?
    params[:ssh_key] = File.open(File.expand_path(ssh_file)) {|file| file.read}

    default_test_pattern = "**/*_spec.rb"
    test_pattern = options[:test_pattern] || ask("Enter a test pattern or press 'Return'. Using #{default_test_pattern} by default:")
    params[:test_pattern] = test_pattern.empty? ? default_test_pattern : test_pattern

    default_suite_name = "#{File.basename(Dir.pwd)}/#{current_git_branch}"
    suite_name = options[:name] || ask("Enter a suite name or press 'Return'. Using '#{default_suite_name}' by default:")
    params[:suite_name] = suite_name.empty? ? default_suite_name : suite_name

    params[:ruby_version] = `ruby -v`.match(/^ruby ([\d\.]+)/)[1]

    call_api(:post, SUITES_PATH, {:suite => params}) do |api_response|
      # Manage git
      `git remote rm #{GIT_REMOTE_NAME}`
      `git remote add #{GIT_REMOTE_NAME} #{tddium_git_repo_uri(params[:suite_name])}`
      git_push

      # Save the created suite
      File.open(".tddium", "w") do |file|
        file.write({current_git_branch => api_response["suite"]["id"]}.to_json)
      end
    end
  end

  desc "spec", "Run the test suite"
  def spec
    start_time = Time.now

    # Require git initialization
    unless File.exists?(".tddium")
      say "tddium suite must be initialized. Try 'tddium suite'."
      return
    end

    # Push the latest code to git
    git_push

    # Get the registered suite_id from the file
    tddium_config = File.open(".tddium") do |file|
      file.read
    end
    suite_id = JSON.parse(tddium_config)[current_git_branch]

    # Call the API to get the suite and its tests
    call_api(:get, "#{SUITES_PATH}/#{suite_id}") do |api_response|
      test_pattern = api_response["suite"]["test_pattern"]
      test_files = Dir.glob(test_pattern).collect {|file_path| {:test_name => file_path}}

      # Create a session
      call_api(:post, SESSIONS_PATH) do |api_response|
        session_id = api_response["session"]["id"]

        # Call the API to register the tests
        call_api(:post, "#{SESSIONS_PATH}/#{session_id}/#{REGISTER_TEST_EXECUTIONS_PATH}", {:suite_id => suite_id, :tests => test_files}) do |api_response|
          # Start the tests
          call_api(:post, "#{SESSIONS_PATH}/#{session_id}/#{START_TEST_EXECUTIONS_PATH}") do |api_response|
            say "Ctrl-C to terminate the process"
            tests_not_finished_yet = true
            finished_tests = {}
            test_statuses = Hash.new(0)
            api_call_successful = true
            while tests_not_finished_yet && api_call_successful do
              # Poll the API to check the status (with timeout)
              api_call_successful = call_api(:get, "#{SESSIONS_PATH}/#{session_id}/#{TEST_EXECUTIONS_PATH}") do |api_response|
                # Print out the progress of running tests
                api_response["tests"].each do |test_name, result_params|
                  test_status = result_params["status"]
                  if result_params["end_time"] && !finished_tests[test_name]
                    message = case test_status
                            when "passed" then [".", :green]
                            when "failed" then ["F", :red]
                            when "error" then ["E"]
                            when "pending" then ["*", :yellow]
                          end
                    finished_tests[test_name] = test_status
                    test_statuses[test_status] += 1
                    say message[0], message[1]
                  end
                end

                # If all tests finished, exit the loop
                tests_not_finished_yet = false if finished_tests.size == api_response["tests"].size
              end
            end

            # Print out the result
            say "Finished in #{Time.now - start_time} seconds"
            say "#{finished_tests.size} examples, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending"
            say "You can check out the test report details at #{api_response["report"]}"
          end
        end
      end
    end
  end

  private

  def call_api(method, api_path, params = {}, &block)
    http = HTTParty.send(method, tddium_uri(api_path), :body => params)
    response = JSON.parse(http.body) rescue {}

    if http.success?
      if response["status"] == 0
        yield response
      else
        message = "An error occured: #{response["explanation"]}"
      end
    else
      message = "An error occured: #{http.response.header.msg}"
      message << " #{response["explanation"]}" if response["status"].to_i > 0
    end
    say message if message
    message.nil?
  end

  def git_push
    `git push #{GIT_REMOTE_NAME} #{current_git_branch}`
  end

  def tddium_uri(path, api_version = API_VERSION)
    URI.join(API_HOST, "#{api_version}/#{path}").to_s
  end

  def tddium_git_repo_uri(suite_name)
    repo_name = suite_name.split("/").first
    git_uri = URI.parse(API_HOST)
    git_uri.scheme = GIT_REMOTE_SCHEME
    git_uri.userinfo = GIT_REMOTE_USER
    git_uri.path = "#{GIT_REMOTE_ABSOLUTE_PATH}/#{repo_name}"
    git_uri.to_s
  end

  def current_git_branch
    @current_git_branch ||= File.basename(`git symbolic-ref HEAD`.gsub("\n", ""))
  end
end
