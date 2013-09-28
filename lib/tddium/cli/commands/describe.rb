# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    map "show" => :describe
    desc "describe SESSION", "Describe the state of a session"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :all, :type=>:boolean, :default=>false
    method_option :type, :type=>:string, :default=>nil
    method_option :json, :type=>:boolean, :default=>false
    method_option :names, :type=>:boolean, :deafult=>false
    def describe(session_id)
      tddium_setup({:repo => false})

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
