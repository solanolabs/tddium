=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium
  desc "logout", "Log out of tddium"
  def logout
    set_shell
    set_default_environment
    FileUtils.rm(tddium_file_name) if File.exists?(tddium_file_name)
    say Text::Process::LOGGED_OUT_SUCCESSFULLY
  end
end


