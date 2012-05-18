# Copyright (c) 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "web [SESSION_ID]", "Open build report in web browser"
    def web(*args)
      tddium_setup({:login => false, :git => false})

      session_id = args.first
      if session_id then
        fragment = "1/reports/#{session_id.to_i}" if session_id =~ /^[0-9]+$/
      end
      fragment ||= 'latest'

      begin
        Launchy.open("https://#{@tddium_client.host}/#{fragment}")
      rescue Launchy::Error => e
        exit_failure e.message
      end
    end
  end
end
