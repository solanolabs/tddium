# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved
require 'tddium/commit_log_parser'
require 'digest'

module Tddium
  class TddiumCli < Thor
    map "cucumber" => :spec
    map "test" => :spec
    map "run" => :spec
    desc "run [PATTERN]", "Run the test suite, or tests that match PATTERN"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :user_data_file, :type => :string, :default => nil
    method_option :max_parallelism, :type => :numeric, :default => nil
    method_option :test_pattern, :type => :string, :default => nil
    method_option :force, :type => :boolean, :default => false
    method_option :quiet, :type => :boolean, :default => false
    method_option :machine, :type => :boolean, :default => false
    method_option :session_id, :type => :numeric, :default => nil
    method_option :tool, :type => :hash, :default => {}
    method_option :no_ci, :type => :boolean, :default => true
    method_option :enable_ci, :type => :boolean, :default => false
    def spec(*pattern)
      machine_data = {}

      tddium_setup({:repo => true})

      suite_auto_configure unless options[:machine]

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
        suite_details = @tddium_api.get_suite_by_id(
          @tddium_api.current_suite_id, session_id: options[:session_id])

        tries += 1

        if suite_details["repoman_current"] == true
          break
        else
          say Text::Process::GIT_REPO_WAIT
          sleep @api_config.git_ready_sleep
        end
      end
      exit_failure Text::Error::GIT_REPO_NOT_READY unless suite_details["repoman_current"]

      update_suite_parameters!(suite_details, options[:session_id])

      start_time = Time.now

      # Push the latest code to git
      git_repo_uri = suite_details["git_repo_uri"]
      if !Tddium::Git.update_git_remote_and_push(git_repo_uri) then
        exit_failure Text::Error::GIT_PUSH_FAILED
      end

      commits = CommitLogParser.new(Tddium::Git.latest_commit).commits
      commits_packed = MessagePack.pack(commits)
      commits_encoded = Base64.encode64(commits_packed)

      cache_control_config = @repo_config['cache'] || @repo_config[:cache] || {}
      cache_control_paths = cache_control_config['key_paths'] || cache_control_config[:key_paths]
      cache_control_paths ||= ["Gemfile.lock", "requirements.txt", "packages.json"]
      cache_control_paths.reject!{|x| x =~ /tddium.yml$/}

      cache_control_data = {}
      cache_control_paths.each do |p|
        if File.exists?(p)
          cache_control_data[p] = Digest::SHA1.file(p).to_s
        end
      end
      cache_control_encoded = Base64.encode64(MessagePack.pack(cache_control_data))

      new_session_params = {
        :commits_encoded => commits_encoded,
        :cache_control_encoded => cache_control_encoded
      }

      # Create a session
      # or use an already-created session
      #
      if options[:session_id] && options[:session_id] > 0
        session_id = options[:session_id]
        @tddium_api.update_session(session_id, new_session_params) rescue nil
      else
        session_id = @tddium_api.create_session(@tddium_api.current_suite_id, new_session_params)["id"]
      end

      machine_data[:session_id] = session_id

      # Register the tests
      @tddium_api.register_session(session_id, @tddium_api.current_suite_id, test_pattern)

      # Start the tests
      start_test_executions = @tddium_api.start_session(session_id, test_execution_params)
      num_tests_started = start_test_executions["started"].to_i

      say Text::Process::STARTING_TEST % num_tests_started.to_s

      tests_finished = false
      finished_tests = {}
      latest_message = -100000
      test_statuses = Hash.new(0)
      session_status = nil
      messages = nil
      last_finish_timestamp = nil

      report = start_test_executions["report"]
      say ""
      say Text::Process::CHECK_TEST_REPORT % report unless options[:machine]
      say Text::Process::TERMINATE_INSTRUCTION unless options[:machine]
      say ""

      # Catch Ctrl-C to interrupt the test
      Signal.trap(:INT) do
        say Text::Process::INTERRUPT
        say Text::Process::CHECK_TEST_STATUS
        tests_finished = true
        session_status = "interrupted"
      end

      while !tests_finished do
        # Poll the API to check the status
        if options[:machine]
          result = @tddium_api.check_session_done(session_id)
          tests_finished = result["done"]
          session_status = result["session_status"]
        else
          current_test_executions = @tddium_api.poll_session(session_id)
          session_status = current_test_executions['session_status']

          messages, latest_message = update_messages(latest_message,
                                                     finished_tests,
                                                     messages,
                                                     current_test_executions["messages"])

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
              last_finish_timestamp = Time.now
              test_statuses[test_status] += 1
              say *message
            end
          end

           # XXX time out if all tests are done and the session isn't done.
          if current_test_executions['session_done'] ||
             (finished_tests.size >= num_tests_started && (Time.now - last_finish_timestamp) > Default::TEST_FINISH_TIMEOUT)
            tests_finished = true
          end
        end

        sleep(Default::SLEEP_TIME_BETWEEN_POLLS) if !tests_finished
      end

      # If we haven't been polling messages, get them all at the end.
      if options[:machine]
        current_test_executions = @tddium_api.poll_session(session_id)
        messages, latest_message = update_messages(latest_message,
                                                   finished_tests,
                                                   messages,
                                                   current_test_executions["messages"],
                                                   false)
        current_test_executions["tests"].each do |test_name, result_params|
          test_status = result_params["status"]
          finished_tests[test_name] = test_status
          test_statuses[test_status] += 1
        end
      end

      display_alerts(messages, 'error', Text::Status::SPEC_ERRORS)

      # Print out the result
      say "" if !options[:machine]
      say Text::Process::RUN_TDDIUM_WEB if !options[:machine]
      say ""
      say Text::Process::FINISHED_TEST % (Time.now - start_time)
      say "#{finished_tests.size} tests, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending, #{test_statuses["skipped"]} skipped"

      if !options[:machine] && test_statuses['failed'] > 0
        say ""
        say Text::Process::FAILED_TESTS
        finished_tests.each do |name, status|
          next if status != 'failed'
          say " - #{name}"
        end
        say ""
      end

      say Text::Process::SUMMARY_STATUS % session_status
      say ""

      suite = suite_details.merge({"id" => @tddium_api.current_suite_id})
      @api_config.set_suite(suite)
      @api_config.write_config

      exit_failure if session_status != 'passed'
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
            if !options[:quiet] || m["level"] == 'error' then
              display_message(m)
            end
            latest_message = seqno
          end
        end
      end
      [messages, latest_message]
    end
  end
end
