# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    map "show" => :describe
    desc "describe SESSION", "Describe the state of a session, if it is
    provided; otherwise, the latest session on current branch."
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :all, :type=>:boolean, :default=>false
    method_option :type, :type=>:string, :default=>nil
    method_option :json, :type=>:boolean, :default=>false
    method_option :names, :type=>:boolean, :deafult=>false
    def describe(*args)
      tddium_setup({:repo => false})

      session_id = args.first
      if !session_id then
        # params to get the most recent session on current branch
        suite_params = {
          :suite_id => @tddium_api.current_suite_id,
          :active => false,
          :limit => 1
        } if suite_for_current_branch?

        sessions = @tddium_api.get_sessions(suite_params)
        if sessions.empty? then
          exit_failure Text::Status::NO_INACTIVE_SESSION
        else
          session_id = sessions[0]['id']
        end
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

        say Text::Process::DESCRIBE_SESSION % [session_id, options[:all] ? 'all' : 'failed']

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
