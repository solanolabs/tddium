# Copyright (c) 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    desc "web", "Open most recent build in a web browser"
    def web
      set_default_environment

      begin
        Launchy.open("https://#{tddium_client.host}/latest")
      rescue TddiumClient::Error::Base
        exit_failure
      end
    end
  end
end
