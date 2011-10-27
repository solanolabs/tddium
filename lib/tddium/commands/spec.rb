=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium
  map "cucumber" => :spec
  map "test" => :spec
  map "run" => :spec
  desc "spec [PATTERN]", "Run the test suite, or tests that match PATTERN"
  method_option :user_data_file, :type => :string, :default => nil
  method_option :max_parallelism, :type => :numeric, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  method_option :force, :type => :boolean, :default => false
  method_option :machine, :type => :boolean, :default => false
  def spec(*pattern)
    machine_data = {}

    set_shell
    set_default_environment
    git_version_ok
    exit_failure unless git_repo? && tddium_settings && suite_for_current_branch?

    if git_changes then
      exit_failure(Text::Error::GIT_CHANGES_NOT_COMMITTED) if !options[:force]
      warn(Text::Warning::GIT_CHANGES_NOT_COMMITTED)
    end

    test_execution_params = {}

    if user_data_file_path = options[:user_data_file]
      if File.exists?(user_data_file_path)
        user_data = File.open(user_data_file_path) { |file| file.read }
        test_execution_params[:user_data_text] = Base64.encode64(user_data)
        test_execution_params[:user_data_filename] = File.basename(user_data_file_path)
        say Text::Process::USING_SPEC_OPTION[:user_data_file] % user_data_file_path
      else
        exit_failure Text::Error::NO_USER_DATA_FILE % user_data_file_path
      end
    end

    if max_parallelism = options[:max_parallelism]
      test_execution_params[:max_parallelism] = max_parallelism
      say Text::Process::USING_SPEC_OPTION[:max_parallelism] % max_parallelism
    end
    
    test_pattern = nil

    if pattern.is_a?(Array) && pattern.size > 0
      test_pattern = pattern.join(",")
    end

    test_pattern ||= options[:test_pattern]
    if test_pattern
      say Text::Process::USING_SPEC_OPTION[:test_pattern] % test_pattern
    end

    start_time = Time.now

    # Call the API to get the suite and its tests
    suite_details = call_api(:get, current_suite_path)

    exit_failure Text::Error::GIT_REPO_NOT_READY unless suite_details["suite"]["repoman_current"]

    # Push the latest code to git
    exit_failure Text::Error::GIT_PUSH_FAILED unless update_git_remote_and_push(suite_details)

    # Create a session
    new_session = call_api(:post, Api::Path::SESSIONS)
    machine_data[:session_id] = session_id = new_session["session"]["id"]

    # Register the tests
    call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::REGISTER_TEST_EXECUTIONS}", {:suite_id => current_suite_id, :test_pattern => test_pattern})

    # Start the tests
    start_test_executions = call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::START_TEST_EXECUTIONS}", test_execution_params)

    num_tests_started = start_test_executions["started"].to_i
    
    say Text::Process::STARTING_TEST % num_tests_started.to_s

    tests_not_finished_yet = true
    finished_tests = {}
    latest_message = -1
    test_statuses = Hash.new(0)

    say Text::Process::CHECK_TEST_REPORT % start_test_executions["report"] unless options[:machine]
    say Text::Process::TERMINATE_INSTRUCTION unless options[:machine]
    
    # Catch Ctrl-C to interrupt the test
    Signal.trap(:INT) do
      say Text::Process::INTERRUPT
      say Text::Process::CHECK_TEST_STATUS
      tests_not_finished_yet = false
    end

    while tests_not_finished_yet do
      # Poll the API to check the status
      current_test_executions = call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::TEST_EXECUTIONS}")

      messages = current_test_executions["messages"]
      if !options[:machine] && finished_tests.size == 0 && messages 
        messages.each do |m|
          if m["seqno"] > latest_message
            color = case m["level"]
                      when "error" then :red
                      when "warn" then :yellow
                      else nil
                    end
            print " ---> "
            say m["text"], color
          end
          latest_message = m["seqno"] if m["seqno"] > latest_message
        end
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
                      when "skipped" then [".", :yellow, false]
                      else [".", nil, false]
                    end
          finished_tests[test_name] = test_status
          test_statuses[test_status] += 1
          say *message
        end
      end

      # If all tests finished, exit the loop else sleep
      if finished_tests.size >= num_tests_started
        tests_not_finished_yet = false
      else
        sleep(Default::SLEEP_TIME_BETWEEN_POLLS)
      end
    end

    # Print out the result
    say ""
    say Text::Process::FINISHED_TEST % (Time.now - start_time)
    say "#{finished_tests.size} tests, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending"

    write_suite(suite_details["suite"].merge({"id" => current_suite_id}))

    exit_failure if test_statuses["failed"] > 0 || test_statuses["error"] > 0
  rescue TddiumClient::Error::Base
    exit_failure "Failed due to error communicating with Tddium"
  rescue RuntimeError => e
    exit_failure "Failed due to internal error: #{e.inspect} #{e.backtrace}"
  ensure
    if options[:machine] && machine_data.size > 0
      say "%%%% TDDIUM CI DATA BEGIN %%%%"
      say YAML.dump(machine_data)
      say "%%%% TDDIUM CI DATA END %%%%"
    end
  end
end
