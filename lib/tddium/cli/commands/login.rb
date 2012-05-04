# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "login", "Log in to tddium using your email address and password"
    method_option :email, :type => :string, :default => nil
    method_option :password, :type => :string, :default => nil
    method_option :ssh_key_file, :type => :string, :default => nil
    def login(*args)
      user_details = tddium_setup({:login => false, :git => false})

      login_options = options.dup
      login_options[:email] ||= args.first if args.first

      if user_details then
        say Text::Process::ALREADY_LOGGED_IN
      elsif user = @tddium_api.login_user(:params => @tddium_api.get_user_credentials(login_options), :show_error => true)
        say Text::Process::LOGGED_IN_SUCCESSFULLY 
        if Tddium::Git.git_repo? then
          suites = @tddium_api.get_suites({:repo_name => Tddium::Git.git_repo_name})
          suites.each do |ste|
            @api_config.set_suite(ste)
          end
        end
        @api_config.write_config
      else
        exit_failure
      end
      if prompt_missing_ssh_key
        say Text::Process::NEXT_STEPS
      end
    end
  end
end
