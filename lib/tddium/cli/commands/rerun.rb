# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "rerun SESSION", "Rerun failing tests from a session"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :max_parallelism, :type => :numeric, :default => nil
    method_option :no_op, :type=>:boolean, :default => false, :aliases => ["-n"]
    method_option :force, :type=>:boolean, :default => false
    method_option :local, :type=>:boolean, :default => false
    def rerun(session_id)
      tddium_setup({:repo => false})

      result = @tddium_api.query_session(session_id)
      tests = result['session']['tests']
      tests = tests.select{ |t| ['failed', 'error'].include?(t['status']) }
      tests = tests.map{ |t| t['test_name'] }

      if options[:local]
        cmd = "ruby -rbundler/setup #{tests.map { |t| "-r./#{t}" }.join(" ")} -e ''"
      else
        cmd = "tddium run"
        cmd += " --max-parallelism=#{options[:max_parallelism]}" if options[:max_parallelism]
        cmd += " --org=#{options[:account]}" if options[:account]
        cmd += " --force" if options[:force]
        cmd += " #{tests.join(" ")}"
      end

      say cmd
      Kernel.exec(cmd) if !options[:no_op]
    end
  end
end
