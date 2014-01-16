# Copyright (c) 2011-2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "stop [SESSION]", "Stop session by id"
    def stop(ls_id=nil)
      if ls_id
        say "To activate your account, please visit"
        say "https://api.tddium.com/"
      else
        say 'Please add id run `tddium stop 7869764` for example'
      end
    end
  end
end
