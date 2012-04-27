# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "password", "Change password"
    map "passwd" => :password
    def password
      set_shell
      set_default_environment
      exit_failure unless @api_config.valid?
      user_details = user_logged_in?
      exit_failure unless user_details

      params = {}
      params[:current_password] = HighLine.ask(Text::Prompt::CURRENT_PASSWORD) { |q| q.echo = "*" }
      params[:password] = HighLine.ask(Text::Prompt::NEW_PASSWORD) { |q| q.echo = "*" }
      params[:password_confirmation] = HighLine.ask(Text::Prompt::PASSWORD_CONFIRMATION) { |q| q.echo = "*" }

      begin
        user_id = user_details["user"]["id"]
        result = call_api(:put, "#{Api::Path::USERS}/#{user_id}/", {:user=>params}, nil, false)
        say Text::Process::PASSWORD_CHANGED
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::PASSWORD_ERROR % e.explanation
      rescue TddiumClient::Error::Base => e
        exit_failure e.message
      end
    end
  end
end
