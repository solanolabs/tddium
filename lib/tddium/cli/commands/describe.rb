# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    map "show" => :describe
    desc "describe [SESSION]", "Describe the state of a session, if it
    is provided; otherwise, the latest session on current branch."
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :all, :type=>:boolean, :default=>false
    method_option :type, :type=>:string, :default=>nil
    method_option :json, :type=>:boolean, :default=>false
    method_option :names, :type=>:boolean, :default=>false
    def describe(session_id=nil)
      tddium_setup({:repo => false})

      status_message = ''
      if !session_id then
        # params to get the most recent session id on current branch
        suite_params = {
          :suite_id => @tddium_api.current_suite_id,
          :active => false,
          :limit => 1
        } if suite_for_current_branch?

        sessions = suite_params ? @tddium_api.get_sessions(suite_params) : []
        if sessions.empty? then
          exit_failure Text::Status::NO_INACTIVE_SESSION
        end

        session_id = sessions[0]['id']

        session_status = sessions[0]['status'].upcase
        session_commit = sessions[0]['commit']
        current_commit = Tddium::Git.git_current_commit
        if session_commit == current_commit
          commit_message = "equal to your current commit"
        else
          cnt_ahead = Tddium::Git.git_number_of_commits(session_commit, current_commit)
          if cnt_ahead == 0
            cnt_behind = Tddium::Git.git_number_of_commits(current_commit, session_commit)
            commit_message = "your workspace is behind by #{cnt_behind} commits"
          else
            commit_message = "your workspace is ahead by #{cnt_ahead} commits"
          end
        end

        duration = sessions[0]['duration']
        start_timeago = "%s ago" % Tddium::TimeFormat.seconds_to_human_time(Time.now - Time.parse(sessions[0]["start_time"]))
        if duration.nil?
          finish_timeago = "no info about duration found, started #{start_timeago}"
        elsif session_status == 'RUNNING'
          finish_timeago = "in process, started #{start_timeago}"
        else
          finish_time = Time.parse(sessions[0]["start_time"]) + duration
          finish_timeago = "%s ago" % Tddium::TimeFormat.seconds_to_human_time(Time.now - finish_time)
        end

        status_message = Text::Status::SESSION_STATUS % [session_commit, commit_message, session_status, finish_timeago]
      end

      result = @tddium_api.query_session(session_id)

      filtered = result['session']['tests']
      if !options[:all]
        filtered = filtered.select{|x| x['status'] == 'failed'}
      end

      if options[:type]
        filtered = filtered.select{|x| x['test_type'].downcase == options[:type].downcase}
      end

      if options[:json]
        puts JSON.pretty_generate(result['session'])
      elsif options[:names]
        say filtered.map{|x| x['test_name']}.join(" ")
      else
        filtered.sort!{|a,b| [a['test_type'], a['test_name']] <=> [b['test_type'], b['test_name']]}

        say Text::Process::DESCRIBE_SESSION % [session_id, status_message, options[:all] ? 'all' : 'failed']

        table = 
          [["Test", "Status", "Duration"],
           ["----", "------", "--------"]] +
          filtered.map do |x|
          [
            x['test_name'],
            x['status'],
            x['elapsed_time'] ? "#{x['elapsed_time']}s" : "-"
          ]
        end
        print_table table
      end
    end
  end
end
