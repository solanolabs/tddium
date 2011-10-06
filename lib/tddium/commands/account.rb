=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium

  desc "account", "View account information"
  def account
    set_shell
    set_default_environment
    if user_details = user_logged_in?(true, true)
      # User is already logged in, so just display the info
      show_user_details(user_details)
    else
      exit_failure Text::Error::USE_ACTIVATE
    end
  end

  desc "account:add [ROLE] [EMAIL]", "Authorize and invite a user to use your account"
  define_method "account:add" do |role, email|
    set_shell
    set_default_environment
    user_details = user_logged_in?(true, true)
    exit_failure unless user_details

    params = {:role=>role, :email=>email}
    begin
      say Text::Process::ADDING_MEMBER % [params[:email], params[:role]]
      result = call_api(:post, Api::Path::MEMBERSHIPS, params)
      say Text::Process::ADDED_MEMBER % email
    rescue TddiumClient::Error::API => e
      exit_failure Text::Error::ADD_MEMBER_ERROR % [email, e.message]
    end
  end

  desc "account:remove [EMAIL]", "Remove a user from your account"
  define_method "account:remove" do |email|
    set_shell
    set_default_environment
    user_details = user_logged_in?(true, true)
    exit_failure unless user_details

    begin
      say Text::Process::REMOVING_MEMBER % email
      result = call_api(:delete, "#{Api::Path::MEMBERSHIPS}/#{email}")
      say Text::Process::REMOVED_MEMBER % email
    rescue TddiumClient::Error::API => e
      exit_failure Text::Error::REMOVE_MEMBER_ERROR % [email, e.message]
    end
  end
end
