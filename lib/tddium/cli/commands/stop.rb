# Copyright (c) 2011-2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "stop [SESSION]", "Stop session by id"
    def stop(ls_id=nil)
      tddium_setup
      if ls_id
        origin_url = Tddium::Git.git_origin_url
        repo_params = {
          :active => false, 
          :repo_url => origin_url
        }
        res = @tddium_api.get_sessions(repo_params)
        puts res
      else
        say 'Please add id - run `tddium stop 7869764` for example'
      end
    end
  end
end
