# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "status", "Display information about this suite, and any open dev sessions"
    def status
      tddium_setup

      begin
        current_suites = @tddium_api.get_suites
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
  end
end  
