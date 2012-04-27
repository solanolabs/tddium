# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "logout", "Log out of tddium"
    def logout
      set_shell
      set_default_environment
      FileUtils.rm(tddium_file_name) if File.exists?(tddium_file_name)
      say Text::Process::LOGGED_OUT_SUCCESSFULLY
    end
  end
end
