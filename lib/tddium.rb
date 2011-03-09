=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require "rubygems"
require "thor"
require "httparty"
require "json"
require "config/constants"

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

  attr_accessor :environment

  desc "suite", "Register the suite for this project, or manage its settings"
  method_option :ssh_key, :type => :string, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  method_option :name, :type => :string, :default => nil
  method_option :environment, :type => :string, :default => nil
  def suite
    set_default_environment(options[:environment])
    return unless git_repo? && tddium_settings

    # Inputs for API call
    params = {}

    ssh_file = options[:ssh_key] || ask(Text::Prompt::SSH_KEY)
    ssh_file = Default::SSH_FILE if ssh_file.empty?
    params[:ssh_key] = File.open(File.expand_path(ssh_file)) {|file| file.read}

    test_pattern = options[:test_pattern] || ask(Text::Prompt::TEST_PATTERN)
    params[:test_pattern] = test_pattern.empty? ? Default::TEST_PATTERN : test_pattern

    if current_suite_id.nil?
      default_suite_name = "#{File.basename(Dir.pwd)}/#{current_git_branch}"
      suite_name = options[:name] || ask(Text::Prompt::SUITE_NAME % default_suite_name)
      params[:suite_name] = suite_name.empty? ? default_suite_name : suite_name
      params[:ruby_version] = `ruby -v`.match(/^ruby ([\d\.]+)/)[1]
    end

    if current_suite_id
      # Update the current suite if it exists already
      call_api(:put, "#{Api::Path::SUITE}/#{current_suite_id}", {:suite => params})
    else
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
            api_call_successful = true

            say Text::Process::STARTING_TEST % test_files.size
            say Text::Process::TERMINATE_INSTRUCTION
            while tests_not_finished_yet && api_call_successful do
              # Poll the API to check the status
              api_call_successful = call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::TEST_EXECUTIONS}") do |api_response|
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

    call_api(:get, current_suite_path) do |api_response|
      hidden_settings = %w{id user_id updated_at created_at}
      api_response["suite"].each do |suite_setting, value|
        say("#{suite_setting.gsub("_", " ").capitalize}: #{value}") unless hidden_settings.include?(suite_setting)
      end
    end
  end

  private

  def call_api(method, api_path, params = {}, &block)
    headers = { Api::KEY_HEADER => tddium_settings(false)["api_key"] } if tddium_settings(false) && tddium_settings(false)["api_key"]
    http = HTTParty.send(method, tddium_uri(api_path), :body => params, :headers => headers)
    response = JSON.parse(http.body) rescue {}

    if http.success?
      if response["status"] == 0
        yield response
      else
        message = Text::Error::API + response["explanation"].to_s
      end
    else
      message = Text::Error::API + http.response.header.msg.to_s
      message << " #{response["explanation"]}" if response["status"].to_i > 0
    end
    say message if message
    message.nil?
  end

  def git_push
    `git push #{Git::REMOTE_NAME} #{current_git_branch}`
  end

  def tddium_uri(path)
    uri = URI.parse("")
    uri.host = tddium_config["api"]["host"]
    uri.port = tddium_config["api"]["port"]
    uri.scheme = tddium_config["api"]["scheme"]
    URI.join(uri.to_s, "#{tddium_config["api"]["version"]}/#{path}").to_s
  end

  def tddium_git_repo_uri(suite_name)
    repo_name = suite_name.split("/").first
    git_uri = URI.parse("")
    git_uri.host = tddium_config["git"]["host"]
    git_uri.scheme = tddium_config["git"]["scheme"]
    git_uri.userinfo = tddium_config["git"]["user"]
    git_uri.path = "#{tddium_config["git"]["absolute_path"]}/#{repo_name}"
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
    extension = ".#{environment}" unless environment == "production"
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

  def tddium_config
   unless @tddium_config
     @tddium_config = YAML.load(
       File.read(File.join("config", "environment.yml"))
     )[environment]
   end
   @tddium_config
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
      self.environment = "development"
      self.environment = "production" unless File.exists?(tddium_file_name)
    else
      self.environment = env
    end
  end
end
