# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "rerun [SESSION]", "Rerun failing tests from a session"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :user_data_file, :type => :string, :default => nil
    method_option :max_parallelism, :type => :numeric, :default => nil
    method_option :machine, :type => :boolean, :default => false
    def rerun(*args)
      tddium_setup({:repo => false})

      session_id = args.first || 'latest'

      result = @tddium_api.query_session(session_id)
      tests = result['session']['tests']
      tests = tests.select { |t| ['failed', 'error'].include?(t['status']) }
      tests = tests.map { |t| t['test_name'] }

      Kernel.exec("tddium run #{tests.join(' ')}")
    end
  end
end
