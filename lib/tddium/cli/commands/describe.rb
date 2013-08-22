# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "describe <session>", "Describe the state of a session"
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    def describe(*args)
      tddium_setup({:repo => false})

      session_id = args.first

      result = @tddium_api.query_session(session_id)

      puts JSON.pretty_generate(result['session'])
    end
  end
end
