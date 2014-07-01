# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "rerun SESSION", "Rerun failing tests from a session"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :max_parallelism, :type => :numeric, :default => nil
    method_option :no_op, :type=>:boolean, :default => false, :aliases => ["-n"]
    method_option :force, :type=>:boolean, :default => false
    def rerun(session_id=nil)
      tddium_setup({:repo => false})

      session_id ||= session_id_for_current_suite

      result = @tddium_api.query_session(session_id)
      tests = result['session']['tests']
      tests = tests.select{ |t| ['failed', 'error'].include?(t['status']) }
      tests = tests.map{ |t| t['test_name'] }

      cmd = "tddium run"
      cmd += " --max-parallelism=#{options[:max_parallelism]}" if options[:max_parallelism]
      cmd += " --org=#{options[:account]}" if options[:account]
      cmd += " --force" if options[:force]
      cmd += " #{tests.join(" ")}"

      say cmd
      Kernel.exec(cmd) if !options[:no_op]
    end

    private

    def session_id_for_current_suite
      return unless suite_for_current_branch?
      suite_params = {
        :suite_id => @tddium_api.current_suite_id,
        :active => false,
        :limit => 1
      }
      session = @tddium_api.get_sessions(suite_params)
      session[0]["id"]
    end
  end
end
