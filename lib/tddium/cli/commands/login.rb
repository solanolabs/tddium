# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "login", "Log in to tddium using your email address and password"
    method_option :email, :type => :string, :default => nil
    method_option :password, :type => :string, :default => nil
    method_option :ssh_key_file, :type => :string, :default => nil
    def login(*args)
      set_shell
      set_default_environment

      login_options = options.dup
      login_options[:email] ||= args.first if args.first

      if user_logged_in?
        say Text::Process::ALREADY_LOGGED_IN
      elsif user = login_user(:params => get_user_credentials(login_options), :show_error => true)
        say Text::Process::LOGGED_IN_SUCCESSFULLY 
        if git_repo? then
          suites = get_suites({:repo_name => git_repo_name})
          suites.each do |ste|
            tddium_write_suite(ste)
          end
        end
      else
        exit_failure
      end
      if prompt_missing_ssh_key
        say Text::Process::NEXT_STEPS
      end
    end
  end
end
