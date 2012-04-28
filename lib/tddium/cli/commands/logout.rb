# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "logout", "Log out of tddium"
    def logout
      tddium_setup({:login => false, :git => false})

      file_name = @api_config.tddium_file_name
      FileUtils.rm_f(file_name) if File.exists?(file_name)

      say Text::Process::LOGGED_OUT_SUCCESSFULLY
    end
  end
end
