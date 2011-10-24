=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium
  desc "heroku", "Connect Heroku account with Tddium"
  method_option :email, :type => :string, :default => nil
  method_option :password, :type => :string, :default => nil
  method_option :ssh_key_file, :type => :string, :default => nil
  method_option :app, :type => :string, :default => nil
  def heroku
    set_shell
    set_default_environment
    git_version_ok
    if user_details = user_logged_in?
      # User is already logged in, so just display the info
      show_user_details(user_details)
    else
      begin
        heroku_config = HerokuConfig.read_config(options[:app])
        # User has logged in to heroku, and TDDIUM environment variables are
        # present
        handle_heroku_user(options, heroku_config)
      rescue HerokuConfig::HerokuNotFound
        gemlist = `gem list heroku`
        msg = Text::Error::Heroku::NOT_FOUND % gemlist
        exit_failure msg
      rescue HerokuConfig::TddiumNotAdded
        exit_failure Text::Error::Heroku::NOT_ADDED
      rescue HerokuConfig::InvalidFormat
        exit_failure Text::Error::Heroku::INVALID_FORMAT
      rescue HerokuConfig::NotLoggedIn
        exit_failure Text::Error::Heroku::NOT_LOGGED_IN
      rescue HerokuConfig::AppNotFound
        exit_failure Text::Error::Heroku::APP_NOT_FOUND % options[:app]
      end
    end
  end
end
