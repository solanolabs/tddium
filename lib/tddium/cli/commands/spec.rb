# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved
require 'digest'

module Tddium
  class TddiumCli < Thor
    map "cucumber" => :spec
    map "test" => :spec
    map "run" => :spec
    desc "run [PATTERN]", "Run the test suite, or tests that match PATTERN"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :tag, :type => :string, :default => nil
    method_option :user_data_file, :type => :string, :default => nil
    method_option :max_parallelism, :type => :numeric, :default => nil
    method_option :test_pattern, :type => :string, :default => nil
    method_option :test_exclude_pattern, :type => :string, :default => nil
    method_option :force, :type => :boolean, :default => false
    method_option :quiet, :type => :boolean, :default => false
    method_option :machine, :type => :boolean, :default => false
    method_option :session_id, :type => :numeric, :default => nil
    method_option :tool, :type => :hash, :default => {}
    def spec(*pattern)
      machine_data = {}

      tddium_setup({:repo => true})

      suite_auto_configure unless options[:machine]

      exit_failure unless suite_for_current_branch?
      exit_failure(Text::Error::NO_SSH_KEY) if @tddium_api.get_keys.empty?

      if @scm.changes?(options) then
        exit_failure(Text::Error::SCM_CHANGES_NOT_COMMITTED) if !options[:force]
        warn(Text::Warning::SCM_CHANGES_NOT_COMMITTED)
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

      test_execution_params[:tag] = options[:tag] if options[:tag]
      test_pattern = nil

      if pattern.is_a?(Array) && pattern.size > 0 then
        test_pattern = pattern.join(",")
      end

      test_pattern ||= options[:test_pattern]
      if test_pattern then
        say Text::Process::USING_SPEC_OPTION[:test_pattern] % test_pattern
      end

      test_exclude_pattern ||= options[:test_exclude_pattern]
      if test_exclude_pattern then
        say Text::Process::USING_SPEC_OPTION[:test_exclude_pattern] % test_exclude_pattern
      end

      tries = 0
      while tries < Default::SCM_READY_TRIES do
        # Call the API to get the suite and its tests
        suite_details = @tddium_api.get_suite_by_id(@tddium_api.current_suite_id,
                                                    :session_id => options[:session_id])

        if suite_details["repoman_current"] == true
          break
        else
          @tddium_api.demand_repoman_account(suite_details["account_id"])

          say Text::Process::SCM_REPO_WAIT
          sleep @api_config.scm_ready_sleep
        end
        
        tries += 1
      end
      exit_failure Text::Error::SCM_REPO_NOT_READY unless suite_details["repoman_current"]

      update_suite_parameters!(suite_details, options[:session_id])

      start_time = Time.now
      
      new_session_params = {
        :commits_encoded => read_and_encode_latest_commits,
        :cache_control_encoded => read_and_encode_cache_control,
        :cache_save_paths_encoded => read_and_encode_cache_save_paths,
        :raw_config_file => read_and_encode_config_file
      }

      # Create a session
      # or use an already-created session
      #
      session_id = options[:session_id]
      session_data = if session_id && session_id > 0
        @tddium_api.update_session(session_id, new_session_params)
      else
        @tddium_api.create_session(@tddium_api.current_suite_id, new_session_params)
      end

      session_data ||= {}
      session_id ||= session_data["id"]

      push_options = {}
      if options[:machine]
        push_options[:use_private_uri] = true
      end

      if !@scm.push_latest(session_data, suite_details, push_options) then
        exit_failure Text::Error::SCM_PUSH_FAILED
      end

      machine_data[:session_id] = session_id

      # Register the tests
      @tddium_api.register_session(session_id, @tddium_api.current_suite_id, test_pattern, test_exclude_pattern)

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

      # In CI mode, just hang up here.  The session will continue running.
      if options[:machine] then
        say Text::Process::BUILD_CONTINUES
        return
      end

      say ""
      say Text::Process::CHECK_TEST_REPORT % report 
      say Text::Process::TERMINATE_INSTRUCTION 
      say ""

      # Catch Ctrl-C to interrupt the test
      Signal.trap(:INT) do
        say Text::Process::INTERRUPT
        say Text::Process::CHECK_TEST_STATUS
        tests_finished = true
        session_status = "interrupted"
      end

      while !tests_finished do
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
            say Text::Process::CHECK_TEST_REPORT % report 
            say Text::Process::TERMINATE_INSTRUCTION
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

        sleep(Default::SLEEP_TIME_BETWEEN_POLLS) if !tests_finished
      end

      display_alerts(messages, 'error', Text::Status::SPEC_ERRORS)

      # Print out the result
      say ""
      say Text::Process::RUN_TDDIUM_WEB
      say ""
      say Text::Process::FINISHED_TEST % (Time.now - start_time)
      say "#{finished_tests.size} tests, #{test_statuses["failed"]} failures, #{test_statuses["error"]} errors, #{test_statuses["pending"]} pending, #{test_statuses["skipped"]} skipped"

      if test_statuses['failed'] > 0
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

    def read_and_encode_latest_commits
      commits = @scm.commits
      commits_packed = Tddium.message_pack(commits)
      commits_encoded = Base64.encode64(commits_packed)
      commits_encoded
    end

    def cache_control_config
      @repo_config['cache'] || {}
    end

    def read_and_encode_cache_control
      cache_key_paths = cache_control_config['key_paths'] || cache_control_config[:key_paths] 
      cache_key_paths ||= ["Gemfile", "Gemfile.lock", "requirements.txt", "packages.json", "package.json"]
      cache_key_paths.reject!{|x| x =~ /(solano|tddium).yml$/}
      cache_control_data = {}
      cache_key_paths.each do |p|
        if File.exists?(p)
          cache_control_data[p] = Digest::SHA1.file(p).to_s
        end
      end

      msgpack = Tddium.message_pack(cache_control_data)
      cache_control_encoded = Base64.encode64(msgpack)
    end

    def read_and_encode_cache_save_paths
      cache_save_paths = cache_control_config['save_paths'] || cache_control_config[:save_paths]
      msgpack = Tddium.message_pack(cache_save_paths)
      cache_save_paths_encoded = Base64.encode64(msgpack)
    end

    def read_and_encode_config_file
      fn = @repo_config.config_filename
      if fn && File.exists?(fn) then
        Base64.encode64(File.read(fn))
      else
        nil
      end
    end
  end
end
