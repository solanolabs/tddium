# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    map "cucumber" => :spec
    map "test" => :spec
    map "run" => :spec
    desc "spec [PATTERN]", "Run the test suite, or tests that match PATTERN"
    method_option :user_data_file, :type => :string, :default => nil
    method_option :max_parallelism, :type => :numeric, :default => nil
    method_option :test_pattern, :type => :string, :default => nil
    method_option :force, :type => :boolean, :default => false
    method_option :machine, :type => :boolean, :default => false
    method_option :tool, :type => :hash, :default => {}
    def spec(*pattern)
      machine_data = {}

      tddium_setup({:repo => true})

      suite_auto_configure

      exit_failure unless suite_for_current_branch?

      if Tddium::Git.git_changes?(:exclude=>".gitignore") then
        exit_failure(Text::Error::GIT_CHANGES_NOT_COMMITTED) if !options[:force]
        warn(Text::Warning::GIT_CHANGES_NOT_COMMITTED)
      end

      test_execution_params = {}

      if user_data_file_path = options[:user_data_file] then
        if File.exists?(user_data_file_path) then
          user_data = File.open(user_data_file_path) { |file| file.read }
          test_execution_params[:user_data_text] = Base64.encode64(user_data)
          test_execution_params[:user_data_filename] = File.basename(user_data_file_path)
          say Text::Process::USING_SPEC_OPTION[:user_data_file] % user_data_file_path
        else
          exit_failure Text::Error::NO_USER_DATA_FILE % user_data_file_path
        end
      end

      if max_parallelism = options[:max_parallelism] then
        test_execution_params[:max_parallelism] = max_parallelism
        say Text::Process::USING_SPEC_OPTION[:max_parallelism] % max_parallelism
      end

      test_pattern = nil

      if pattern.is_a?(Array) && pattern.size > 0 then
        test_pattern = pattern.join(",")
      end

      test_pattern ||= options[:test_pattern]
      if test_pattern then
        say Text::Process::USING_SPEC_OPTION[:test_pattern] % test_pattern
      end

      tries = 0
      while tries < Default::GIT_READY_TRIES do
        # Call the API to get the suite and its tests
        suite_details = @tddium_api.get_suite_by_id(@tddium_api.current_suite_id)

        tries += 1

        if suite_details["repoman_current"] == true
          break
        else
          say Text::Process::GIT_REPO_WAIT
          sleep @api_config.git_ready_sleep
        end
      end
      exit_failure Text::Error::GIT_REPO_NOT_READY unless suite_details["repoman_current"]

      update_suite_parameters!(suite_details)

      start_time = Time.now

      # Push the latest code to git
      git_repo_uri = suite_details["git_repo_uri"]
      if !Tddium::Git.update_git_remote_and_push(git_repo_uri) then
        exit_failure Text::Error::GIT_PUSH_FAILED 
      end

      # Create a session
      new_session = @tddium_api.create_session
      machine_data[:session_id] = session_id = new_session["id"]

      # Register the tests
      @tddium_api.register_session(session_id, @tddium_api.current_suite_id, test_pattern)

      # Start the tests
      start_test_executions = @tddium_api.start_session(session_id, test_execution_params)
      num_tests_started = start_test_executions["started"].to_i

      say Text::Process::STARTING_TEST % num_tests_started.to_s

      tests_not_finished_yet = true
      finished_tests = {}
      latest_message = -1
      test_statuses = Hash.new(0)
      messages = nil
      poll_messages = !options[:machine]

      report = start_test_executions["report"]
      say ""
      say Text::Process::CHECK_TEST_REPORT % report unless options[:machine]
      say Text::Process::TERMINATE_INSTRUCTION unless options[:machine]
      say ""

      # Catch Ctrl-C to interrupt the test
      Signal.trap(:INT) do
        say Text::Process::INTERRUPT
        say Text::Process::CHECK_TEST_STATUS
        tests_not_finished_yet = false
      end

      while tests_not_finished_yet do
        # Poll the API to check the status
        current_test_executions = @tddium_api.poll_session(session_id, :messages=>poll_messages)

        if poll_messages
          messages, latest_message = update_messages(latest_message, 
                                                     finished_tests, 
                                                     messages,
                                                     current_test_executions["messages"])
        end

        # Print out the progress of running tests
        current_test_executions["tests"].each do |test_name, result_params|
          if finished_tests.size == 0 && result_params["finished"] then
            say ""
            say Text::Process::CHECK_TEST_REPORT % report unless options[:machine]
            say Text::Process::TERMINATE_INSTRUCTION unless options[:machine]
            say ""
          end
          if result_params["finished"] && !finished_tests[test_name]
            test_status = result_params["status"]
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

      # If we haven't been polling messages, get them all at the end.
      if !poll_messages
        current_test_executions = @tddium_api.poll_session(session_id, :messages=>true)
        messages, latest_message = update_messages(latest_message, 
                                                     finished_tests, 
                                                     messages,
                                                     current_test_executions["messages"],
                                                    false)
      end

      display_alerts(messages, 'warn', Text::Status::SPEC_WARNINGS)
      display_alerts(messages, 'error', Text::Status::SPEC_ERRORS)

      # Print out the result
      say "" if !options[:machine]
      say Text::Process::RUN_TDDIUM_WEB if !options[:machine]
      say ""
      say Text::Process::FINISHED_TEST % (Time.now - start_time)
      say "#{finished_tests.size} tests, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending, #{test_statuses["skipped"]} skipped"


      suite = suite_details.merge({"id" => @tddium_api.current_suite_id})
      @api_config.set_suite(suite)
      @api_config.write_config

      exit_failure if test_statuses["failed"] > 0 || test_statuses["error"] > 0
    rescue TddiumClient::Error::API => e
      exit_failure "Failed due to error: #{e.explanation}"
    rescue TddiumClient::Error::Base => e
      exit_failure "Failed due to error: #{e.message}"
    rescue RuntimeError => e
      exit_failure "Failed due to internal error: #{e.inspect} #{e.backtrace}"
    ensure
      if options[:machine] && machine_data.size > 0
        say "%%%% TDDIUM CI DATA BEGIN %%%%"
        say YAML.dump(machine_data)
        say "%%%% TDDIUM CI DATA END %%%%"
      end
    end

    private

    def update_messages(latest_message, finished_tests, messages, current, display=true)
      messages = current
      if !options[:machine] && finished_tests.size == 0 && messages 
        messages.each do |m|
          seqno = m["seqno"].to_i
          if seqno > latest_message
            display_message(m)
            latest_message = seqno
          end
        end
      end
      [messages, latest_message]
    end

  end
end
