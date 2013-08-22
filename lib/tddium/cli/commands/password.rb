# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "password", "Change password"
    map "passwd" => :password
    def password
      user_details = tddium_setup({:git => false})

      params = {}
      params[:current_password] = HighLine.ask(Text::Prompt::CURRENT_PASSWORD) { |q| q.echo = "*" }
      params[:password] = HighLine.ask(Text::Prompt::NEW_PASSWORD) { |q| q.echo = "*" }
      params[:password_confirmation] = HighLine.ask(Text::Prompt::PASSWORD_CONFIRMATION) { |q| q.echo = "*" }

      begin
        user_id = user_details["id"]
        @tddium_api.update_user(user_id, {:user => params})
        say Text::Process::PASSWORD_CHANGED
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::PASSWORD_ERROR % e.explanation
      rescue TddiumClient::Error::Base => e
        exit_failure e.message
      end
    end
  end
end
