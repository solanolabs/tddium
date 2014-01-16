# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module TddiumConstant

  module Dependency
    VERSION_REGEXP = /([\d\.]+)/
  end

  module Default
    SLEEP_TIME_BETWEEN_POLLS = 2
    
    ENVIRONMENT = "production"
    SSH_FILE = "~/.ssh/id_rsa.pub"
    SUITE_TEST_PATTERN = "features/**.feature, spec/**_spec.rb, spec/features/**.feature, test/**_test.rb"
    SSH_OUTPUT_DIR = "~/.ssh/"

    GIT_SERVER = "git.tddium.com"
    READY_TRIES = 3
    GIT_READY_TRIES = 18
    GIT_READY_SLEEP = 10
    TEST_FINISH_TIMEOUT = 15 * 60 # 15 minutes
  end

  module Config
    REMOTE_NAME = "tddium"
    GIT_IGNORE = ".gitignore"
    CONFIG_PATHS = ["tddium.yml",
                    "config/tddium.yml",
                    "config/tddium.cfg",
                    ]
  end

  module Api
    module Path
      SUITES = "suites"
      SESSIONS = "sessions"
      REPORTS = "reports"
      USERS = "users"
      SIGN_IN = "#{USERS}/sign_in"
      TEST_EXECUTIONS = "test_executions"
      QUERY_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/query"
      REGISTER_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/register"
      START_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/start"
      REPORT_TEST_EXECUTIONS = "#{TEST_EXECUTIONS}/report"
      ACCOUNT_USAGE_BY_ACCOUNT = "accounts/usage_by_account"
      MEMBERSHIPS = "memberships"
      INSTANCES = "instances"
      KEYS = "keys"
      CONFIG = "env"
      ACCOUNTS = "accounts"
      REPOS = "repos"
    end
  end

  module License
    FILE_NAME = File.expand_path(File.join("..", "..", "..", "LICENSE.txt"), __FILE__)
  end

  module Text
    module Prompt
      module Response
        YES = "y"
        DISABLE = 'disable'
      end
      SSH_KEY = "Enter your ssh key or press 'Return'. Using '%s' by default:"
      SUITE_NAME = "Enter a repo name or press 'Return'. Using '%s' by default:"
      EMAIL = "Enter your email address: "
      CURRENT_PASSWORD = "Enter your old password: "
      PASSWORD = "Enter password: "
      NEW_PASSWORD = "Enter a new password: "
      PASSWORD_CONFIRMATION = "Confirm your password: "
      INVITATION_TOKEN = "Enter your activation token:"
      TEST_PATTERN = "Enter a pattern or press 'Return'. Using '%s' by default:"
      CI_PULL_URL = "Enter git URL to pull from (default '%s') or enter 'disable':"
      CI_PUSH_URL = "Enter git URL to push to (default '%s') or enter 'disable':"
      CAMPFIRE_ROOM = "Custom Campfire room for this suite (current: '%s') or enter 'disable':"
      HIPCHAT_ROOM = "Custom HipChat room for this suite (current: '%s') or enter 'disable':"
      ACCOUNT = "Enter the organization to create the suite under:"
      ACCOUNT_DEFAULT = "Enter the organization to create the suite under (default: '%s'):"
    end

    module Warning
      USE_PASSWORD_TOKEN = "If you signed up with Github, use token from web dashboard as password"
      GIT_VERSION = "Unsupported git version: %s"
      GIT_CHANGES_NOT_COMMITTED = "There are uncommitted changes in the local git repository"
      GIT_UNABLE_TO_DETECT = "Unable to detect uncommitted git changes"
      YAML_PARSE_FAILED = "Unable to parse %s as YAML"
    end

    module Process
      SSH_KEY_NEEDED = "\nIt looks like you haven't authorized an SSH key to use with Tddium.\n\n"
      DEFAULT_KEY_ADDED = "SSH key authorized."
      NO_KEYS = "No authorized keys."
      ADD_KEYS_ADD = "Adding key '%s'"
      ADD_KEYS_ADD_DONE =<<EOF
Authorized key '%s'.

Assuming your private key is in %s, you can just add the following 
to ~/.ssh/config to use this new key with Tddium:

# Tddium SSH Config
Host %s
  IdentityFile %s
  IdentitiesOnly yes
EOF
      ADD_KEYS_GENERATE = "Generating key '%s'"
      ADD_KEYS_GENERATE_DONE =<<EOF
Generated and authorized key '%s'.

Append the following to ~/.ssh/config to use this new key with Tddium:

# Tddium SSH Config
Host %s
  IdentityFile %s
  IdentitiesOnly yes
EOF
      REMOVE_KEYS = "Removing key '%s'"
      REMOVE_KEYS_DONE = "Removed key '%s'"

      NO_CONFIG = "No environment variables configured."
      ADD_CONFIG = "Adding config %s=%s to %s"
      ADD_CONFIG_DONE = "Added config %s=%s to %s"
      REMOVE_CONFIG = "Removing config '%s' from %s"
      REMOVE_CONFIG_DONE = "Removed config '%s' from %s"
      CONFIG_EDIT_COMMANDS =<<EOF

Use `tddium config:add <scope> <key> <value>` to set a config key.
Use `tddium config:remove <scope> <key>` to remove a key.

EOF
      KEYS_EDIT_COMMANDS =<<EOF

Use `tddium keys:add` to generate and authorize a new SSH keypair.
Use `tddium keys:remove` to remove an authorized key from Tddium.

Use `ssh-keygen -lf <filename>` to print fingerprint of an existing public key.

EOF
      TEST_PATTERN_INSTRUCTIONS =<<EOF

>>> Tddium selects tests to run by default (e.g., in CI) by matching against a
    list of Ruby glob patterns.  Use "," to join multiple globs.

    You can instead specify a list of test patterns in config/tddium.yml.

    Read more here: https://www.tddium.com/support/reference#customization

EOF
      NO_CONFIGURED_SUITE = "Looks like you haven't configured Tddium on this computer for %s/%s...\n"
      FOUND_EXISTING_SUITE = "Found a suite in Tddium for\n\n%s\n\n(on branch %s)."
      TERMINATE_INSTRUCTION = ">>> Press Ctrl-C to stop waiting.  Tests will continue running.\n"
      INTERRUPT = "Interrupted"
      GIT_PUSH = ">>> Pushing changes to Tddium..."
      GIT_REPO_WAIT = ">>> Waiting for your repository to be prepared. Sleeping for 10 seconds..."
      STARTING_TEST = ">>> Starting Session with %s tests..."
      CHECK_TEST_STATUS = ">>> Use 'tddium status' to check on pending jobs"
      FINISHED_TEST = "Finished in %s seconds"
      RUN_TDDIUM_WEB = "\n>>> Run `tddium web` to open the latest test results in your browser.\n"
      CHECK_TEST_REPORT = ">>> To view results, visit: %s"
      FAILED_TESTS = "Failed tests:"
      SUMMARY_STATUS = "Final result: %s."
      EXISTING_SUITE = "\nCurrent suite:\n"
      USING_EXISTING_SUITE = "Using suite '%s/%s'."
      CREATING_SUITE = "Creating suite '%s/%s'.  This will take a few seconds."
      CREATING_SUITE_CI_DISABLED = "Disabling automatic CI for this new branch."
      CREATED_SUITE = "\nCreated suite.\n"
      PASSWORD_CONFIRMATION_INCORRECT = "Password confirmation incorrect"
      PASSWORD_CHANGED = "Your password has been changed."
      NEXT_STEPS = "

Next, you should register your test suite and start tests by running:

$ tddium run

"
      ALREADY_LOGGED_IN = "You're already logged in"
      LOGGED_IN_SUCCESSFULLY = "Logged in successfully"
      LOGGED_OUT_SUCCESSFULLY = "Logged out successfully"
      USING_SPEC_OPTION = {:max_parallelism => "Max number of tests in parallel = %s",
                           :user_data_file => "Sending user data from %s",
                           :test_pattern => "Selecting tests that match '%s'"}
      REMEMBERED = " (Remembered value)"
      UPDATED_SUITE = "Updated suite successfully."
      UPDATED_TEST_PATTERN = "Updated test pattern to '%s'"
      UPDATED_RUBY_VERSION = "Updated ruby version to '%s'"
      UPDATED_BUNDLER_VERSION = "Updated bundler version to '%s'"
      UPDATED_PYTHON_CONFIG = "Updated Python configuration:\n%s"
      UPDATED_TEST_CONFIGS = "Updated test configurations:\n%s"
      DEPENDENCY_VERSION = "... Detected %s %s"
      CONFIGURED_VERSION = "Configured %s %s from %s"
      CONFIGURED_PATTERN =<<EOF;
... Configured test pattern from %s:

%s

>>> To change the pattern:
    1. Edit %s
    2. Run `tddium suite --edit` again.
EOF
      DETECTED_BRANCH = "... Detected branch %s"
      SETUP_CI=<<EOF;

>>> To set up Hosted CI, enter a git URL to pull from. 
    You can also set a git URL to push to after tests pass.

>>> Set both pull and push URLs to 'disable' to disable hosted CI completely.

EOF
      SETUP_CAMPFIRE=<<EOF;


EOF

      ADDING_MEMBER = "Adding %s as %s..."
      ADDED_MEMBER = "Added %s"
      REMOVING_MEMBER = "Removing %s. This may take a few seconds..."
      REMOVED_MEMBER = "Removed %s"

      USING_ACCOUNT_FROM_FLAG = "Using organization '%s' (from command line)."
      USING_ACCOUNT = "Using organization '%s'."

      CONFIRM_DELETE_SUITE = <<EOF.rstrip
Are you sure you want to delete the suite %s/%s
in organization %s?
This will delete all sessions associated with this suite, and cannot be un-done.
y/[n]:
EOF
      SUITE_IN_MULTIPLE_ACCOUNTS = "The suite %s/%s exists in multiple organization:"
      SUITE_IN_MULTIPLE_ACCOUNTS_PROMPT = "Which organization do you want to delete it from:"

      ABORTING = "Aborting."
      DESCRIBE_SESSION =<<EOF

Session %d%s
Showing %s tests

EOF
      RERUN_SESSION =<<EOF

Re-run failures from a session with `tddium rerun <session_id>`.
Extract details of a session with `tddium describe <session_id>`.

EOF
    end

    module Status
      SPEC_WARNINGS = "\n\n>>> Tddium Warnings:\n\n"
      SPEC_ERRORS = "\n\n>>> Tddium Errors:\n"
      NO_SUITE = "You currently do not have any suites"
      ALL_SUITES = "Suites:"
      CURRENT_SUITE = "Current suite: %s"
      CURRENT_SUITE_UNAVAILABLE = "Your current suite is unavailable"
      NO_ACTIVE_SESSION = "There are no running sessions for this repo."
      ACTIVE_SESSIONS = "Your active sessions for this repo%s:"
      NO_INACTIVE_SESSION = "There are no recent sessions on this branch."
      INACTIVE_SESSIONS = "Latest sessions on branch %s:"
      SESSION_DETAIL = " %10.10s %s %s in %s, %s"
      ATTRIBUTE_DETAIL = "    %s: %s"
      SEPARATOR = "====="
      USING_SUITE = "\nUsing suite:\n"
      USER_DETAILS =<<EOF;

Username: <%=user["email"]%>
User created: <%=user["created_at"]%>
EOF
      ACCOUNT_DETAILS =<<EOF;

Organization: <%=acct["account"]%>

  Role: <%=acct["account_role"]%>
  Owner: <%=acct["account_owner"]%>
  Plan: <%=acct["plan"]%>
<% if acct["trial_remaining"] && acct["trial_remaining"] > 0 %>  Trial Period Remaining: <%=acct["trial_remaining"]%> days<% end %>
<% if acct["account_url"] %>  Organization Management URL: <%=acct["account_url"]%><% end %>
<% if acct["heroku"] %>  Heroku Account Linked: <%=acct["heroku_activation_done"]%><% end %>
<% if acct["third_party_pubkey"] %>
  >>> Authorize the following SSH public key to allow Tddium's test workers to
  install gems from private git repos or communicate via SSH to your servers:

    <%= acct["third_party_pubkey"] %>

<%end%>
EOF
      USER_THIRD_PARTY_KEY_DETAILS =<<EOF;
<% if user["third_party_pubkey"] %>
>>> Authorize the following SSH public key to allow Tddium's test workers to
install gems from private git repos or communicate via SSH to your servers:

    <%= user["third_party_pubkey"] %>
<%end%>
EOF

      SUITE_DETAILS =<<EOF;
  Organization:         <%=suite["account"]%>
  Repo:                 <%=suite["repo_url"]%>
  Branch:               <%=suite["branch"]%>
  Default Test Pattern: <%=suite["test_pattern"]%>
  Ruby Version:         <%=suite["ruby_version"]%>
  Rubygems Version:     <%=suite["rubygems_version"]%>
  Bundler Version:      <%=suite["bundler_version"]%>
<% if suite["ci_enabled"] %>
Tddium Hosted CI is enabled with the following parameters:

  Pull URL:             <%=suite["ci_pull_url"]%>
  Push URL:             <%=suite["ci_push_url"]%>

Notifications:

<%=suite["ci_notifications"]%>

<% if suite["ci_pull_url"] =~ /^git@github.com:(.*).git$/ %>
>>> Tddium will pull from your Github repository.

    Visit https://github.com/<%= $1 %>/admin/keys
    then click "Add another deploy key" and copy and paste this key:

    <%=suite["ci_ssh_pubkey"]%>
<% else %>
>>> Authorize the following SSH key to let Tddium's pulls and pushes through:

<%=suite["ci_ssh_pubkey"]%>
<% end %><% if suite["ci_push_url"] =~ /^git@heroku.com:(.*).git$/ %>
>>> Tddium will push to your Heroku application <%= $1 %>.
    To authorize the key, use the following command:

    heroku keys:add <%= tddium_deploy_key_file_name %> --app <%= $1 %>
<% end %><% if suite["ci_pull_url"] =~ /^git@github.com:(.*).git$/ %>
>>> Configure Github to notify Tddium of your commits with a post-receive hook.

    Visit https://github.com/<%= $1 %>/admin/hooks#generic_minibucket
    then add the following URL and click "Update Settings":
    <%=suite["hook_uri"]%>
<% else %>
>>> In order for Tddium to know that your repo has changed, you'll need to
    configure a post-commit hook in your Git server.

    In Unix-based Git repositories, find the repository root and look for
    a shell script in `.git/hooks/post-commit`.

    To trigger CI builds, POST to the following URL from a post-commit hook:
    <%=suite["hook_uri"]%>
<% end %>

>>> See http://www.tddium.com/support for more information on Tddium CI.
>>> You can enable Campfire and HipChat notifications from your Tddium Dashboard.
<% end %>
>>> Run 'tddium suite --edit' to edit these settings.
>>> Run 'tddium spec' to run tests in this suite.
EOF
      ACCOUNT_MEMBERS = "Authorized users:"
      KEYS_DETAILS =<<EOF

You have authorized the following SSH public keys to communicate with Tddium:

 Name               Fingerprint
 ------------------ ------------------------------------------------------------
EOF
      CONFIG_DETAILS =<<EOF
The following environment variables are set for this %s:

EOF
      SESSION_STATUS =<<EOF

Session Details:

 Commit: %s (%s)
 Status: %s
 Finished: %s

EOF
    end

    module Error
      KEY_ALREADY_EXISTS = "Aborting. SSH key already exists: %s"
      KEYGEN_FAILED = "Failed to generate new SSH key for '%s'"
      LIST_KEYS_ERROR = "Error listing SSH keys"
      REMOVE_KEYS_ERROR = "Failed to remove key '%s'"
      ADD_KEYS_DUPLICATE = "You already have a key named '%s'"
      ADD_KEYS_ERROR = "Failed to add key '%s'"
      LIST_CONFIG_ERROR = "Error listing configuration variables"
      ADD_CONFIG_ERROR = "Error settng configuration variable"
      REMOVE_CONFIG_ERROR = "Error removing configuration variable"
      GIT_NOT_A_REPOSITORY = "Current working directory is not a git repository"
      INVALID_CONFIGURED_PATTERN =<<EOF;
Configuring test pattern from %s...

>>> The test_pattern in %s is not properly formatted.  It must be a YAML list.

You entered:

%s

>>> Edit %s and rerun `tddium suite --edit`

EOF
      GIT_REPO_NOT_READY = "Your git repository is being prepped.  Try again in a minute."
      GIT_PUSH_FAILED = <<EOF;

The git push to Tddium failed.

If you get a "Permission denied (publickey)" message, ensure that SSH is
configured to send a key you have authorized with Tddium (Run `tddium keys` to
see a list.)

For any other error, contact us at: support@tddium.com


EOF
      INVALID_SSH_PUBLIC_KEY = '%s does not appear to be a valid SSH public key'
      INACCESSIBLE_SSH_PUBLIC_KEY = '%s is not accessible: %s'
      GIT_CHANGES_NOT_COMMITTED =<<EOF
There are uncommitted changes in the local git repository.

Commit changes before running 'tddium spec'.

Use 'tddium spec --force' to test with only already-committed changes.
EOF
      NOT_INITIALIZED = "Tddium must be initialized. Try 'tddium login'"
      INVALID_TDDIUM_FILE = ".tddium.%s config file is corrupt. Try 'tddium login'"
      GIT_NOT_FOUND = "Tddium requires git and git is not on your PATH"
      GIT_NOT_INITIALIZED =<<EOF;
It doesn't look like you're in a git repo.  If you're not, use 'git init' to
create one.

If you are in a git repo and you're still seeing this message,
you may be using an unsupported version of git.

Please email us at info@tddium.com with the following trace information:

>>>>>>>>>>>>> BEGIN GIT TRACE >>>>>>>>>>>>>>>>>>>>>>>>>
git version: #{`git --version 2>&1`}
git status:  #{`git status 2>&1`}
git status result: #{ $? }
git details: #{`git status --porcelain 2>&1`}
git details result: #{ $? }
>>>>>>>>>>>>> END GIT TRACE   >>>>>>>>>>>>>>>>>>>>>>>>>
EOF
      NO_SUITE_EXISTS = "No suite exists for the branch '%s'. Try running 'tddium suite'"
      TRY_DEFAULT_BRANCH = "Getting suites for default '%s' branch."
      NO_USER_DATA_FILE = "User data file '%s' does not exist"
      NO_MATCHING_FILES = "No files match '%s'"
      PASSWORD_ERROR = "Error changing password: %s"
      ADD_MEMBER_ERROR = "Error adding %s: %s"
      REMOVE_MEMBER_ERROR = "Error removing %s: %s"
      USE_ACTIVATE = "Visit 'https://api.tddium.com' to activate your account for the first time."
      INVALID_CREDENTIALS = "Your .tddium file has an invalid API key.\nRun `tddium logout` and `tddium login`, and then try again."
      MISSING_ACCOUNT_OPTION = "You must specify an organization by passing the --org option."
      MISSING_ACCOUNT = "You must specify an organization."
      NOT_IN_ACCOUNT = "You aren't a member of organization %s."
      CANT_FIND_SUITE = "Can't find suite for %s/%s"
      INVALID_ACCOUNT_NAME = "Invalid organization name."
    end
  end

  module DisplayedAttributes
    SUITE = %w{repo_url branch test_pattern
               ruby_version bundler_version rubygems_version
               test_scripts test_executions git_repo_uri}
    TEST_EXECUTION = %w{start_time end_time test_execution_stats report}
  end
end
