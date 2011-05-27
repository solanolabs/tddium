=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

module TddiumConstant

  module Dependency
    VERSION_REGEXP = /([\d\.]+)/
  end

  module Default
    SLEEP_TIME_BETWEEN_POLLS = 2
    ENVIRONMENT = "production"
    SSH_FILE = "~/.ssh/id_rsa.pub"
    TEST_PATTERN = "spec/**/*_spec.rb"
  end

  module Git
    REMOTE_NAME = "tddium"
    GITIGNORE = ".gitignore"
  end

  module Api
    module Path
      SUITES = "suites"
      SESSIONS = "sessions"
      USERS = "users"
      SIGN_IN = "#{USERS}/sign_in"
      TEST_EXECUTIONS = "test_executions"
      REGISTER_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/register"
      START_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/start"
      REPORT_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/report"
      ACCOUNT_USAGE = "accounts/usage"
    end
    module ErrorCode
      INVALID_INVITATION = 2
    end
  end

  module License
    FILE_NAME = "LICENSE.txt"
  end

  module Text
    module Prompt
      module Response
        AGREE_TO_LICENSE = "I AGREE"
        YES = "y"
      end
      SSH_KEY = "Enter your ssh key or press 'Return'. Using '%s' by default:"
      SUITE_NAME = "Enter a suite name or press 'Return'. Using '%s' by default:"
      LICENSE_AGREEMENT = "Type '%s' to accept the license and continue:" % Response::AGREE_TO_LICENSE
      EMAIL = "Enter your email address:"
      CURRENT_PASSWORD = "Enter your old password: "
      PASSWORD = "Enter password: "
      NEW_PASSWORD = "Enter a new password: "
      PASSWORD_CONFIRMATION = "Confirm your password: "
      INVITATION_TOKEN = "Enter your invitation token:"
      USE_EXISTING_SUITE = "The suite name '%s' already exists. Enter '#{Response::YES}' to use it, or enter a new name:"
    end

    module Process
      TERMINATE_INSTRUCTION = "Press Ctrl-C to stop waiting.  Tests will continue running."
      INTERRUPT = "Interrupted"
      STARTING_TEST = "Starting %s tests..."
      CHECK_TEST_STATUS = "Use 'tddium status' to check on pending jobs"
      FINISHED_TEST = "Finished in %s seconds"
      CHECK_TEST_REPORT = "Test report: %s"
      EXISTING_SUITE = "Current suite: %s"
      CREATING_SUITE = "Creating suite '%s'.  This will take a few seconds."
      PASSWORD_CONFIRMATION_INCORRECT = "Password confirmation incorrect"
      PASSWORD_CHANGED = "Your password has been changed."
      ACCOUNT_CREATED = "
Congratulations %s, your tddium account has been created!

Next, you should:

1. Register your test suite by running:
tddium suite

2. Sign up for a billing plan by opening this URL in your browser:
%s

3. Start tests by running:
tddium spec

"
      ALREADY_LOGGED_IN = "You're already logged in"
      LOGGED_IN_SUCCESSFULLY = "Logged in successfully"
      LOGGED_OUT_SUCCESSFULLY = "Logged out successfully"
      USING_PREVIOUS_USER_DATA_FILE = "Using the previous user data file '%s'"
      USING_PREVIOUS_MAX_PARALLELISM = "Using the previous value of max_parallelism = %s"
      USING_PREVIOUS_TEST_PATTERN = "Using the previous value of test_pattern = %s"
      HEROKU_WELCOME = "
Thanks for installing the Tddium Heroku Add-On!

Next, set a password and provide an SSH key to authenticate your communication
with Tddium.

"
    end

    module Status
      NO_SUITE = "You currently do not have any suites"
      ALL_SUITES = "Your suites: %s"
      CURRENT_SUITE = "Your current suite: %s"
      CURRENT_SUITE_UNAVAILABLE = "Your current suite is unavailable"
      NO_ACTIVE_SESSION = "There are no active sessions"
      ACTIVE_SESSIONS = "Your active sessions:"
      NO_INACTIVE_SESSION = "There are no previous sessions"
      INACTIVE_SESSIONS = "Your latest sessions:"
      SESSION_TITLE = "  Session %s:"
      ATTRIBUTE_DETAIL = "    %s: %s"
      SEPARATOR = "====="
      USING_SUITE = "Using suite: '%s' on branch: '%s'"
      HEROKU_CONFIG = "
Tddium is configured to work with your Heroku app.

Next, you should:

1. Register your test suite by running:

$ tddium suite

2. Start tests by running:

$ tddium spec

"
    end

    module Error
      NOT_INITIALIZED = "tddium must be initialized. Try 'tddium login'"
      INVALID_TDDIUM_FILE = ".tddium.%s config file is corrupt. Try 'tddium login'"
      GIT_NOT_INITIALIZED = "git repo must be initialized. Try 'git init'"
      NO_SUITE_EXISTS = "No suite exists for the branch '%s'. Try running 'tddium suite'"
      INVALID_INVITATION = "
Your invitation token wasn't recognized. If you have a token, make sure you enter it correctly.
If you want an invite, visit this URL to sign up:
http://blog.tddium.com/home/

"
      NO_USER_DATA_FILE = "User data file '%s' does not exist"
      NO_MATCHING_FILES = "No files match '%s'"
      PASSWORD_ERROR = "Error changing password: %s"
      HEROKU_MISCONFIGURED = "There was an error linking your Heroku account to Tddium: %s"
    end
  end

  module DisplayedAttributes
    SUITE = %w{repo_name branch test_pattern
               ruby_version bundler_version rubygems_version
               test_scripts test_executions git_repo_uri}
    TEST_EXECUTION = %w{start_time end_time test_execution_stats report}
  end
end
