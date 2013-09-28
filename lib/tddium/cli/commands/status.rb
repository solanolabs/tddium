# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "status", "Display information about this suite, and any open dev sessions"
    method_option :json, :type => :boolean, :default => false
    def status
      tddium_setup

      begin
        # tddium_setup asserts that we're in a git repo
        origin_url = Tddium::Git.git_origin_url

        if suite_for_current_branch?
          show_session_details({:suite_id=>@tddium_api.current_suite_id, :active => false, :limit => 10}, Text::Status::NO_INACTIVE_SESSION, Text::Status::INACTIVE_SESSIONS, options[:json])
        end
        show_session_details({:active => true, :repo_url=>origin_url}, Text::Status::NO_ACTIVE_SESSION, Text::Status::ACTIVE_SESSIONS, options[:json])

        say Text::Process::RERUN_SESSION
      rescue TddiumClient::Error::Base => e
        exit_failure e.message
      end
    end

    private 

    def show_session_details(params, no_session_prompt, all_session_prompt, json)
      current_sessions = @tddium_api.get_sessions(params)
      
      if json
        scope = params[:suite_id] ? @tddium_api.current_branch : params[:repo_url]
        puts JSON.pretty_generate({scope => current_sessions})
        return
      end

      say ""
      if current_sessions.empty? then
        say no_session_prompt
      else
        say all_session_prompt % (params[:suite_id] ? @tddium_api.current_branch : "")
        say ""
        table = [
          ["Session #", "Commit", "Status", "Duration", "Started"],
          ["---------", "------", "------", "--------", "-------"],
        ] + current_sessions.map do |session|
          duration = "%ds" % session['duration']
          start_timeago = "%s ago" % Tddium::TimeFormat.seconds_to_human_time(Time.now - Time.parse(session["start_time"]))

          ["#{session["id"]}",
            session["commit"] ? session['commit'][0...7] : '-      ',
            session["status"],
            duration,
            start_timeago]
        end
        print_table table
      end
    end

  end
end  
