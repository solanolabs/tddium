# Copyright (c) 2011-2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "stop [SESSION]", "Stop session by id"
    def stop(ls_id=nil)
      tddium_setup({:scm => false})
      if ls_id
        begin
          say "Stoping session #{ls_id} ..."
          say @tddium_api.stop_session(ls_id)['notice']
        rescue 
        end
      else
        say 'Stop requires a session id -- e.g. `tddium stop 7869764`'
      end
    end
  end
end
