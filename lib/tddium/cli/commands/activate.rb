# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "activate", "Activate an account with an invitation token"
    method_option :email, :type => :string, :default => nil
    method_option :password, :type => :string, :default => nil
    method_option :ssh_key_file, :type => :string, :default => nil
    def activate
      set_shell
      set_default_environment
      git_version_ok
      if user_details = user_logged_in?
        exit_failure Text::Error::ACTIVATE_LOGGED_IN
      else
        params = get_user_credentials(options.merge(:invited => true))

        # Prompt for the password confirmation if password is not from command line
        unless options[:password]
          password_confirmation = HighLine.ask(Text::Prompt::PASSWORD_CONFIRMATION) { |q| q.echo = "*" }
          unless password_confirmation == params[:password]
            exit_failure Text::Process::PASSWORD_CONFIRMATION_INCORRECT
          end
        end

        begin
          params[:user_ssh_key] = prompt_ssh_key(options[:ssh_key_file])
        rescue TddiumError => e
          exit_failure e.message
        end

        # Prompt for accepting terms
        say Text::Process::TERMS_OF_SERVICE
        license_accepted = ask(Text::Prompt::LICENSE_AGREEMENT)
        exit_failure unless license_accepted.downcase == Text::Prompt::Response::AGREE_TO_LICENSE.downcase

        begin
          say Text::Process::STARTING_ACCOUNT_CREATION
          new_user = call_api(:post, Api::Path::USERS, {:user => params}, false, false)
          tddium_write_api_key(new_user["user"]["api_key"])
          role = new_user["user"]["account_role"]
          if role.nil? || role == "owner"
            u = new_user["user"]
            say Text::Process::ACCOUNT_CREATED % [u["email"], u["trial_remaining"], u["recurly_url"]]
          else
            say Text::Process::ACCOUNT_ADDED % [new_user["user"]["email"], new_user["user"]["account_role"], new_user["user"]["account"]]
          end
        rescue TddiumClient::Error::API => e
          exit_failure ((e.status == Api::ErrorCode::INVALID_INVITATION) ? Text::Error::INVALID_INVITATION : e.message)
        rescue TddiumClient::Error::Base => e
          exit_failure say e.message
        end
      end
    end
  end
end
