# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "status", "Display information about this suite, and any open dev sessions"
    def status
      tddium_setup

      begin
        current_suites = @tddium_api.get_suites(:repo_url => Tddium::Git.git_origin_url)
        if current_suites.empty? then
          say Text::Status::NO_SUITE
        else
          if current_suite = current_suites.detect {|suite| suite["id"] == @tddium_api.current_suite_id}
            say Text::Status::CURRENT_SUITE % current_suite["repo_name"]
            show_attributes(DisplayedAttributes::SUITE, current_suite)
            say Text::Status::SEPARATOR
          else
            say Text::Status::CURRENT_SUITE_UNAVAILABLE
          end
        end
        show_session_details({:active => false, :order => "date", :limit => 10}, Text::Status::NO_INACTIVE_SESSION, Text::Status::INACTIVE_SESSIONS)
        show_session_details({:active => true, :order => "date"}, Text::Status::NO_ACTIVE_SESSION, Text::Status::ACTIVE_SESSIONS)
      rescue TddiumClient::Error::Base => e
        exit_failure e.message
      end
    end

    private 

    def show_session_details(params, no_session_prompt, all_session_prompt)
      current_sessions = @tddium_api.get_sessions(params)
      say Text::Status::SEPARATOR
      if current_sessions.empty? then
        say no_session_prompt
      else
        say all_session_prompt
        current_sessions.reverse_each do |session|
          duration = "(%ds)" % ((session["end_time"] ? Time.parse(session["end_time"]) : Time.now) - Time.parse(session["start_time"])).round
          say Text::Status::SESSION_DETAIL % [session["report"],
                                              duration,
                                              session["start_time"],
                                              session["test_execution_stats"]]
        end
      end
    end

  end
end  
