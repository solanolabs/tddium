# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "status", "Display information about this suite, and any open dev sessions"
    method_option :json, :type => :boolean, :default => false
    def status
      tddium_setup

      begin
        # tddium_setup asserts that we're in a git repo
        origin_url = @scm.origin_url
        repo_params = {
          :active => true, 
          :repo_url => origin_url
        }

        if suite_for_current_branch? then
          status_branch = @tddium_api.current_branch
          suite_params = {
            :suite_id => @tddium_api.current_suite_id,
            :active => false,
            :limit => 10
          }
        elsif suite_for_default_branch? then
          status_branch = @tddium_api.default_branch
          say Text::Error::TRY_DEFAULT_BRANCH % status_branch
          suite_params = {
            :suite_id => @tddium_api.default_suite_id,
            :active => false,
            :limit => 10
          }
        end

        if options[:json] 
          res = {}
          res[:running] = { origin_url => @tddium_api.get_sessions(repo_params) }          
          res[:history] = { 
            status_branch => @tddium_api.get_sessions(suite_params)
          } if suite_params
          puts JSON.pretty_generate(res)
        else
          running_sessions = Thread.new { @tddium_api.get_sessions(repo_params) }
          branch_sessions = Thread.new { @tddium_api.get_sessions(suite_params) }

          show_session_details(
            running_sessions.value,
            status_branch,
            repo_params, 
            Text::Status::NO_ACTIVE_SESSION, 
            Text::Status::ACTIVE_SESSIONS,
            true
          )
          show_session_details(
            branch_sessions.value,
            status_branch,
            suite_params, 
            Text::Status::NO_INACTIVE_SESSION, 
            Text::Status::INACTIVE_SESSIONS,
            false
          ) if suite_params
          say Text::Process::RERUN_SESSION
        end

      rescue TddiumClient::Error::Base => e
        exit_failure e.message
      end
    end

    private 

    def show_session_details(current_sessions, status_branch, params, no_session_prompt, all_session_prompt, include_branch)
      say ""
      if current_sessions.empty? then
        say no_session_prompt
      else
        commit_size = 0...7
        head = @scm.current_commit[commit_size]

        say all_session_prompt % (params[:suite_id] ? status_branch : "")
        say ""
        header = ["Session #", "Commit", ("Branch" if include_branch), "Status", "Duration", "Started"].compact
        table = [header, header.map { |t| "-" * t.size }] + current_sessions.map do |session|
          duration = "%ds" % session['duration']
          start_timeago = "%s ago" % Tddium::TimeFormat.seconds_to_human_time(Time.now - Time.parse(session["start_time"]))

          [
            session["id"].to_s,
            session["commit"] ? session['commit'][commit_size] : '-      ',
            (session["branch"] if include_branch),
            session["status"],
            duration,
            start_timeago
          ].compact
        end
        say(capture_stdout { print_table table }.gsub(head, "\e[7m#{head}\e[0m"))
      end
    end

    def capture_stdout
      old, $stdout = $stdout, StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old
    end
  end
end  
