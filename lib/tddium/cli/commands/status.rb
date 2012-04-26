# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    desc "status", "Display information about this suite, and any open dev sessions"
    def status
      set_shell
      set_default_environment
      git_version_ok
      exit_failure unless git_repo? && tddium_settings

      begin
        current_suites = call_api(:get, Api::Path::SUITES)
        if current_suites["suites"].size == 0
          say Text::Status::NO_SUITE
        else
          if current_suite = current_suites["suites"].detect {|suite| suite["id"] == current_suite_id}
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
