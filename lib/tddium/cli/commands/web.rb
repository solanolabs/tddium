# Copyright (c) 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "web", "Open build report in web browser"
    def web(*args)
      set_default_environment

      session_id = args.first
      if session_id then
        fragment = "1/reports/#{session_id.to_i}" if session_id =~ /^[0-9]+$/
      end
      fragment ||= 'latest'

      begin
        Launchy.open("https://#{tddium_client.host}/#{fragment}")
      rescue TddiumClient::Error::Base
        exit_failure
      end
    end
  end
end
