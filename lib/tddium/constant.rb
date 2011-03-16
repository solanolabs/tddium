=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

module TddiumConstant
  module Default
    SLEEP_TIME_BETWEEN_POLLS = 2
    ENVIRONMENT = "production"
    SSH_FILE = "~/.ssh/id_rsa.pub"
    TEST_PATTERN = "**/*_spec.rb"
  end

  module Git
    REMOTE_NAME = "tddium"
    HOST = "api.tddium.com"
    SCHEME = "ssh"
    ABSOLUTE_PATH = "/home/git/repo"
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
      INCORRECT_PASSWORD = 1
    end
  end

  module Text
    module Prompt
      module Response
        AGREE_TO_LICENSE = "I AGREE"
      end
      SSH_KEY = "Enter your ssh key or press 'Return'. Using '%s' by default:"
      TEST_PATTERN = "Enter a test pattern or press 'Return'. Using '%s' by default:"
      SUITE_NAME = "Enter a suite name or press 'Return'. Using '%s' by default:"
      LICENSE_AGREEMENT = "Type '%s' to accept the license and continue:" % Response::AGREE_TO_LICENSE
      EMAIL = "Enter your email address:"
      PASSWORD = "Enter a password:"
    end

    module Process
      TERMINATE_INSTRUCTION = "Ctrl-C to terminate the process"
      INTERRUPT = "Interrupted"
      STARTING_TEST = "Starting %s tests..."
      CHECK_TEST_STATUS = "Use 'tddium status' to check on pending jobs"
      FINISHED_TEST = "Finished in %s seconds"
      CHECK_TEST_REPORT = "You can check out the test report details at %s"
      UPDATE_SUITE = "The suite has been updated successfully"
      ACCOUNT_TAKEN = "Sorry an account already exists with this email address. If you are the owner of this account try 'tddium login'"
    end

    module Error
      NOT_INITIALIZED = "tddium must be initialized. Try 'tddium login'"
      INVALID_TDDIUM_FILE = ".tddium.%s config file is corrupt. Try 'tddium login'"
      GIT_NOT_INITIALIZED = "git repo must be initialized. Try 'git init'"
      NO_SUITE_EXISTS = "No suite exists for the branch '%s'. Try running 'tddium suite'"
    end
  end
end
