# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def show_config_details(scope, config)
      if !config || config.length == 0
        say Text::Process::NO_CONFIG
      else
        say Text::Status::CONFIG_DETAILS % scope
        config.each do |k,v| 
          say "#{k}=#{v}"
        end
      end
      say Text::Process::CONFIG_EDIT_COMMANDS
    end

    def show_attributes(names_to_display, attributes)
      names_to_display.each do |attr|
        say Text::Status::ATTRIBUTE_DETAIL % [attr.gsub("_", " ").capitalize, attributes[attr]] if attributes[attr]
      end
    end

    def show_keys_details(keys)
      say Text::Status::KEYS_DETAILS
      if keys.length == 0
        say Text::Process::NO_KEYS
      else
        keys.each do |k| 
          if k["fingerprint"]
            say((" %-18.18s %s" % [k["name"], k["fingerprint"]]).rstrip)
          else
            say((" %-18.18s" % k["name"]).rstrip)
          end
        end
      end
      say Text::Process::KEYS_EDIT_COMMANDS
    end

    def show_ssh_config(dir=nil)
      dir ||= ENV['TDDIUM_GEM_KEY_DIR']
      dir ||= Default::SSH_OUTPUT_DIR

      path = File.expand_path(File.join(dir, "identity.tddium.*"))

      Dir[path].reject{|fn| fn =~ /.pub$/}.each do |fn|
        say Text::Process::SSH_CONFIG % {:git=>"git.tddium.com", :file=>fn}
      end
    end

    def show_session_details(params, no_session_prompt, all_session_prompt)
      current_sessions = @tddium_api.get(sessions, params)
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

    def show_user_details(user)
      # Given the user is logged in, he should be able to
      # use "tddium account" to display information about his account:
      # Email address
      # Account creation date
      say ERB.new(Text::Status::USER_DETAILS).result(binding)

      current_suites = @tddium_api.get_suites
      if current_suites.empty? then
        say Text::Status::NO_SUITE
      else
        say Text::Status::ALL_SUITES % current_suites.collect {|suite| "#{suite["repo_name"]}/#{suite["branch"]}"}.join(", ")
      end

      memberships = @tddium_api.get_memberships
      if memberships.length > 1
        say Text::Status::ACCOUNT_MEMBERS
        say memberships.collect{|x|x['display']}.join("\n")
        say "\n"
      end

      account_usage = @tddium_api.get_usage
      say account_usage
    rescue TddiumClient::Error::Base => e
      exit_failure e.message
    end
  end
end
