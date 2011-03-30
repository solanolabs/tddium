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
    TEST_PATTERN = "**/*_spec.rb"
  end

  module Git
    REMOTE_NAME = "tddium"
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
      TEST_PATTERN = "Enter a test pattern or press 'Return'. Using '%s' by default:"
      SUITE_NAME = "Enter a suite name or press 'Return'. Using '%s' by default:"
      LICENSE_AGREEMENT = "Type '%s' to accept the license and continue:" % Response::AGREE_TO_LICENSE
      EMAIL = "Enter your email address:"
      PASSWORD = "Enter a password: "
      PASSWORD_CONFIRMATION = "Confirm your password: "
      INVITATION_TOKEN = "Enter your invitation token:"
      USE_EXISTING_SUITE = "The suite name '%s' already exists. Enter '#{Response::YES}' to use it, or enter a new name:"
    end

    module Process
      TERMINATE_INSTRUCTION = "Ctrl-C to terminate the process"
      INTERRUPT = "Interrupted"
      STARTING_TEST = "Starting %s tests..."
      CHECK_TEST_STATUS = "Use 'tddium status' to check on pending jobs"
      FINISHED_TEST = "Finished in %s seconds"
      CHECK_TEST_REPORT = "You can check out the test report details at %s"
      UPDATE_SUITE = "The suite has been updated successfully"
      PASSWORD_CONFIRMATION_INCORRECT = "Password confirmation incorrect"
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
    end
  end

  module DisplayedAttributes
    SUITE = %w{repo_name branch test_pattern
               ruby_version bundler_version rubygems_version
               test_scripts test_executions git_repo_uri}
    TEST_EXECUTION = %w{start_time end_time test_execution_stats report}
  end
end
