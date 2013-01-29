# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "login [[TOKEN]]", "Log in using your email address or token from dashboard"
    method_option :email, :type => :string, :default => nil
    method_option :password, :type => :string, :default => nil
    method_option :ssh_key_file, :type => :string, :default => nil
    def login(*args)
      user_details = tddium_setup({:login => false, :git => false})

      login_options = options.dup

      if args.first && args.first =~ /@/
        login_options[:email] ||= args.first 
      elsif args.first
        # assume cli token
        login_options[:cli_token] = args.first
      end

      if user_details then
        say Text::Process::ALREADY_LOGGED_IN
      elsif user = @tddium_api.login_user(:params => @tddium_api.get_user_credentials(login_options), :show_error => true)
        say Text::Process::LOGGED_IN_SUCCESSFULLY 
        if Tddium::Git.git_repo? then
          @api_config.populate_branches
        end
        @api_config.write_config
      else
        exit_failure
      end
      if prompt_missing_ssh_key then
        say Text::Process::NEXT_STEPS
      end
    end
  end
end
