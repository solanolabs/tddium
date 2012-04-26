# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    protected

    def get_user
      call_api(:get, Api::Path::USERS, {}, nil, false) rescue nil
    end

    def current_account_id
      if user_details = user_logged_in?(true, false)
        user_details["user"]["account_id"]
      else
        nil
      end
    end

    def get_user_credentials(options = {})
      params = {}
      # prompt for email/invitation and password
      if options[:invited]
        token = options[:invitation_token] || ask(Text::Prompt::INVITATION_TOKEN)
        params[:invitation_token] = token.strip
        params[:password] = options[:password] || HighLine.ask(Text::Prompt::NEW_PASSWORD) { |q| q.echo = "*" }
      else
        params[:email] = options[:email] || ask(Text::Prompt::EMAIL)
        params[:password] = options[:password] || HighLine.ask(Text::Prompt::PASSWORD) { |q| q.echo = "*" }
      end
      params
    end

    def login_user(options = {})
      # POST (email, password) to /users/sign_in to retrieve an API key
      begin
        login_result = call_api(:post, Api::Path::SIGN_IN, {:user => options[:params]}, false, options[:show_error])
        # On success, write the API key to "~/.tddium.<environment>"
        tddium_write_api_key(login_result["api_key"])
      rescue TddiumClient::Error::Base
      end
      login_result
    end

    def user_logged_in?(active = true, message = false)
      result = tddium_settings(:fail_with_message => message) && tddium_settings["api_key"]
      (result && active) ? get_user : result
    end
  end
end
