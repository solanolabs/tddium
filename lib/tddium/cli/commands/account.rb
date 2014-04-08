# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "account", "View account information"
    def account
      user_details = tddium_setup({:git => false})

      if user_details then
        # User is already logged in, so just display the info
        show_user_details(user_details)
      else
        exit_failure Text::Error::USE_ACTIVATE
      end
    end

    desc "account:add [ROLE] [EMAIL]", "Authorize and invite a user to use your organization"
    define_method "account:add" do |role, email|
      tddium_setup({:git => false})

      r = Regexp.new(/\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/)
      if r !~ email then
        exit_failure Text::Error::ADD_MEMBER_ERROR % [email, "Not a valid e-mail address: must be of the form user@host.domain"]
      end

      params = {:role=>role, :email=>email}
      begin
        say Text::Process::ADDING_MEMBER % [params[:email], params[:role]]
        result = @tddium_api.set_memberships(params)
        say Text::Process::ADDED_MEMBER % email
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::ADD_MEMBER_ERROR % [email, e.message]
      end
    end

    desc "account:remove [EMAIL]", "Remove a user from an organization"
    define_method "account:remove" do |email|
      tddium_setup({:git => false})

      begin
        say Text::Process::REMOVING_MEMBER % email
        result = @tddium_api.delete_memberships(email)
        say Text::Process::REMOVED_MEMBER % email
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::REMOVE_MEMBER_ERROR % [email, e.message]
      end
    end
  end
end
