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
    SUITE_TEST_PATTERN = "features/**.feature, spec/**_spec.rb, test/**_test.rb"
  end

  module Config
    CONFIG_PATH = "config/tddium.yml"
  end

  module Git
    REMOTE_NAME = "tddium"
    GITIGNORE = ".gitignore"
    READY_TRIES = 3
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
      MEMBERSHIPS = "memberships"
      KEYS = "keys"
    end
    module ErrorCode
      INVALID_INVITATION = 2
    end
  end

  module License
    FILE_NAME = File.expand_path(File.join("..", "..", "..", "LICENSE.txt"), __FILE__)
  end

  module Text
    module Prompt
      module Response
        AGREE_TO_LICENSE = "I AGREE"
        YES = "y"
        DISABLE = 'disable'
      end
      SSH_KEY = "Enter your ssh key or press 'Return'. Using '%s' by default:"
      SUITE_NAME = "Enter a repo name or press 'Return'. Using '%s' by default:"
      LICENSE_AGREEMENT = "Type '%s' to accept the license and continue:" % Response::AGREE_TO_LICENSE
      EMAIL = "Enter your email address:"
      CURRENT_PASSWORD = "Enter your old password: "
      PASSWORD = "Enter password: "
      NEW_PASSWORD = "Enter a new password: "
      PASSWORD_CONFIRMATION = "Confirm your password: "
      INVITATION_TOKEN = "Enter your invitation token:"
      USE_EXISTING_SUITE = "A suite exists '%%s' (branch %s). Enter '#{Response::YES}' to use it, or enter a new repo name:"
      TEST_PATTERN = "Enter a pattern or press 'Return'. Using '%s' by default:"
      CI_PULL_URL = "Enter git URL to pull from (default '%s') or enter 'disable':"
      CI_PUSH_URL = "Enter git URL to push to (default '%s') or enter 'disable':"
      CAMPFIRE_SUBDOMAIN = "Enter your Campfire subdomain (default '%s') or enter 'disable':"
      CAMPFIRE_ROOM = "Enter the Campfire room name (default '%s'):"
      CAMPFIRE_TOKEN = "Enter your Campfire API Token (default '%s'):"
    end

    module Warning
      GIT_VERSION = "Unsupported git version: %s"
      GIT_CHANGES_NOT_COMMITTED = "There are uncommitted changes in the local git repository"
      GIT_UNABLE_TO_DETECT = "Unable to detect uncommitted git changes"
      YAML_PARSE_FAILED = "Unable to parse %s as YAML"
    end

    module Process
      ADD_KEYS = "Generating key '%s'"
      ADD_KEYS_DONE =<<EOF
Generated and authorized key '%s'.

Add the following to ~/.ssh/config to use this new key with Tddium:

Hostname git.tddium.com
  IdentityFile /home/user/.ssh/identity.tddium.%s
  IdentitiesOnly yes
EOF
      REMOVE_KEYS = "Removing key '%s'"
      REMOVE_KEYS_DONE = "Removed key '%s'"
      KEYS_EDIT_COMMANDS =<<EOF

Use `tddium keys:add` to generate and authorize a new SSH keypair.
Use `tddium keys:remove` to remove an authorized key from Tddium.

Use `ssh-keygen -lf <filename>` to get the fingerprint of an existing public key.

EOF
      TEST_PATTERN_INSTRUCTIONS =<<EOF

>>> Tddium selects tests to run by default (e.g., in CI) by matching against a
    list of Ruby glob patterns.  Use "," to join multiple globs.

    You can instead specify a test pattern Array in config/tddium.yml.

    Read more here: https://www.tddium.com/support/reference#customization

EOF
      NO_CONFIGURED_SUITE = "Looks like you haven't set up a suite on this computer for %s/%s..."
      TERMINATE_INSTRUCTION = "Press Ctrl-C to stop waiting.  Tests will continue running."
      INTERRUPT = "Interrupted"
      GIT_PUSH = "Pushing changes to Tddium..."
      STARTING_TEST = "Starting Session with %s tests..."
      CHECK_TEST_STATUS = "Use 'tddium status' to check on pending jobs"
      FINISHED_TEST = "Finished in %s seconds"
      CHECK_TEST_REPORT = "Test report: %s"
      EXISTING_SUITE = "Current suite...\n\n%s"
      CREATING_SUITE = "Creating suite '%s/%s'.  This will take a few seconds."
      CREATED_SUITE = "Created suite...\n\n%s"
      PASSWORD_CONFIRMATION_INCORRECT = "Password confirmation incorrect"
      PASSWORD_CHANGED = "Your password has been changed."
      ACCOUNT_CREATED = "
Congratulations %s, your tddium account has been created!

Next, you should:

1. Register your test suite by running:
tddium suite

2. Start tests by running:
tddium spec

You have %s days left in your free trial.

To sign up a for a billing plan, open this URL in your browser:

%s

"
      ACCOUNT_ADDED = "
Congratulations %s, your tddium account has been activated.

You are a %s of the account: %s

Next, you should:

1. Register your test suite by running:
tddium suite

2. Start tests by running:
tddium spec
"
      STARTING_ACCOUNT_CREATION = "Creating account.  This may take a few seconds..."
      ALREADY_LOGGED_IN = "You're already logged in"
      LOGGED_IN_SUCCESSFULLY = "Logged in successfully"
      LOGGED_OUT_SUCCESSFULLY = "Logged out successfully"
      USING_SPEC_OPTION = {:max_parallelism => "Max number of tests in parallel = %s",
                           :user_data_file => "Sending user data from %s",
                           :test_pattern => "Selecting tests that match '%s'"}
      REMEMBERED = " (Remembered value)"
      HEROKU_WELCOME = "
Thanks for installing the Tddium Heroku Add-On!

Your tddium username is: %s

"
      HEROKU_ACTIVATE = "
Next, set a password and provide an SSH key to authenticate your communication
with Tddium.
"
      UPDATED_SUITE = "Updated suite successfully."
      DEPENDENCY_VERSION = "Detected %s %s"
      CONFIGURED_VERSION = "Configured %s %s from config/tddium.yml"
      CONFIGURED_PATTERN =<<EOF;
Configured test pattern from config/tddium.yml:

%s

>>> To change the pattern:
    1. Edit config/tddium.yml
    2. Run `tddium suite --edit` again.

EOF
      DETECTED_BRANCH = "Detected branch %s"
      SETUP_CI_FIRST_TIME =<<EOF;

Tddium includes a Hosted Continuous Integration srvice that will run a
CI build when it's triggered by a POST:

1. Pull from your git server
2. Run tests that match the test pattern you saved for this suite
3. Notify you by email and/or campfire
4. Optionally, Tddium CI will then push to a git server (push to URL).  For
   example, enter the git URL to your Heroku staging app.

When everything's been set up, you'll receive an SSH public key to authorize in
git for pulls and pushes, and a Hook URL to configure in a post-commit hook.

Tddium CI will not start builds on its own.

>>> To set up Hosted CI, enter a git URL to pull from.
>>> Set both pull and push URLs to 'disable' to disable hosted CI completely.

EOF
      SETUP_CAMPFIRE_FIRST_TIME =<<EOF;

>>> To enable Campfire notifications, enter your Campfire subdomain, API token, 
    and the room name to post for this suite's builds.

Subdomain and API token are shared by all suites that belong to you.

>>> Leave the Campfire room name blank to disable Campfire for this suite.

EOF

      SETUP_CI_EDIT =<<EOF;

Tddium Hosted CI is enabled for this suite.

Set the "git URL to pull from" to 'disable' to disable CI completely.
Set the "git URL to push to" to 'disable' to disable CI completely.

EOF
      SETUP_CAMPFIRE_EDIT =<<EOF;

Campfire notifications are enabled for this suite.
Subdomain and API token are shared by all suites that belong to you (%s).

Set the "Campfire room name" to 'disable' to disable Campfire notifications
for this suite.
EOF
      ADDING_MEMBER = "Adding %s as %s..."
      ADDED_MEMBER = "Added %s"
      REMOVING_MEMBER = "Removing %s. This may take a few seconds..."
      REMOVED_MEMBER = "Removed %s"
    end

    module Status
      SPEC_WARNINGS = "\n\nWarnings:\n\n"
      SPEC_ERRORS = "\n\nErrors:\n"
      NO_SUITE = "You currently do not have any suites"
      ALL_SUITES = "Your suites: %s"
      CURRENT_SUITE = "Your current suite: %s"
      CURRENT_SUITE_UNAVAILABLE = "Your current suite is unavailable"
      NO_ACTIVE_SESSION = "There are no active sessions"
      ACTIVE_SESSIONS = "Your active sessions:"
      NO_INACTIVE_SESSION = "There are no previous sessions"
      INACTIVE_SESSIONS = "Your latest sessions:"
      SESSION_DETAIL = " open %s # %8.8s Started: %s"
      ATTRIBUTE_DETAIL = "    %s: %s"
      SEPARATOR = "====="
      USING_SUITE = "Using suite...\n\n%s"
      USER_DETAILS =<<EOF;

Username: <%=user["email"]%>
Account Created: <%=user["created_at"]%>
<% if user["trial_remaining"] && user["trial_remaining"] > 0 %>Trial Period Remaining: <%=user["trial_remaining"]%> days<% end %>
<% if user["account_url"] %>Account Management URL: <%=user["account_url"]%><% end %>
<% if user["heroku"] %>Heroku Account Linked: <%=user["heroku_activation_done"]%><% end %>

Test Worker SSH Identity:

<%= user["third_party_pubkey"] %>

>>> Authorize this SSH public key to allow Tddium's test workers to install gems
    from private git repos or communicate via SSH to your servers.

EOF
      HEROKU_CONFIG = "
Tddium is configured to work with your Heroku app.

Next, you should:

1. Register your test suite by running:

$ tddium suite

2. Start tests by running:

$ tddium spec

"
      SUITE_DETAILS =<<EOF;
Repo: <%=suite["repo_name"]%>/<%=suite["branch"]%>
Default Test Pattern: <%=suite["test_pattern"]%>
Ruby Version: <%=suite["ruby_version"]%>
Rubygems Version: <%=suite["rubygems_version"]%>
Bundler Version: <%=suite["bundler_version"]%>
<% if suite["ci_pull_url"] %>
Tddium Hosted CI is enabled with the following parameters:

Pull URL: <%=suite["ci_pull_url"]%>
Push URL: <%=suite["ci_push_url"]%>

Notifications:
<%=suite["ci_notifications"]%>

>>> Authorize the following SSH key to let Tddium's pulls and pushes through:

<%=suite["ci_ssh_pubkey"]%>
<% if suite["ci_pull_url"] =~ /^git@github.com:(.*).git$/ %>
Tddium will pull from your Github repository. Visit

https://github.com/<%= $1 %>/admin/keys

then click "Add another deploy key" and copy and paste the above key.
<% end %>
<% if suite["ci_push_url"] =~ /^git@heroku.com:(.*).git$/ %>
Tddium will push to your Heroku application <%= $1 %>.
To authorize the key, use the following command:

heroku keys:add <%= tddium_deploy_key_file_name %> --app <%= $1 %>
<% end %>

<% if suite["ci_pull_url"] =~ /^git@github.com:(.*).git$/ %>
>>> Github can notify Tddium of your commits with a post-receive hook. Visit

https://github.com/<%= $1 %>/admin/hooks#generic_minibucket

then add the following URL and click "Update Settings":

<%=suite["hook_uri"]%>
<% else %>
>>> In order for Tddium to know that your repo has changed, you'll need to
    configure a post-commit hook in your Git server.

In Unix-based Git repositories, find the repository root and look for a shell
script in `.git/hooks/post-commit`.

To trigger CI builds, POST to the following URL from a post-commit hook:
<%=suite["hook_uri"]%>
<% end %>

>>> See http://www.tddium.com/support for more information on Tddium CI.
<% end %>

If your tests don't require a database or your app uses pure ActiveRecord
you're all set and can now run tddium spec.

>>> If your app needs database-specific features (triggers, stored procedures),
    you'll need to configure a custom database setup hook.

    See http://www.tddium.com/support/reference#setup_hooks to create a Rake
    task for Tddium to set up your database.

Run 'tddium suite --edit' to edit suite settings.

Run 'tddium spec' to run tests in this suite.
EOF
      ACCOUNT_MEMBERS = "\nAuthorized users in this account:\n"
      KEYS_DETAILS =<<EOF

You have authorized the following SSH public keys to communicate with Tddium:

 Name               Fingerprint
 ------------------ -------------------------------------------------------------
EOF
    end

    module Error
      KEY_ALREADY_EXISTS = "Aborting.  SSH key already exists: %s"
      KEYGEN_FAILED = "Failed to generate new SSH key for '%s'"
      LIST_KEYS_ERROR = "Error listing SSH keys"
      REMOVE_KEYS_ERROR = "Failed to remove key '%s'"
      ADD_KEYS_DUPLICATE = "You already have a key named '%s'"
      ADD_KEYS_ERROR = "Failed to add key '%s'"
      INVALID_CONFIGURED_PATTERN =<<EOF;
Configuring test pattern from config/tddium.yml...

>>> The test_pattern in config/tddium.yml is not properly formatted.  It must be a YAML list.

You entered:

%s

>>> Edit config/tddium.yml and rerun `tddium suite --edit`

EOF
      GIT_REPO_NOT_READY = "Your git repository is being prepped.  Try again in a minute."
      GIT_PUSH_FAILED = <<EOF;

The git push to Tddium failed.

SSH may not be configured to authenticate with the keypair you
provided when you set up your account.

See this URL for SSH configuration instructions:

https://www.tddium.com/support/faq#othersshkey

EOF
      INVALID_SSH_PUBLIC_KEY = '%s does not appear to be a valid SSH public key'
      INACCESSIBLE_SSH_PUBLIC_KEY = '%s is not accessible: %s'
      GIT_CHANGES_NOT_COMMITTED =<<EOF
There are uncommitted changes in the local git repository.

Commit changes before running 'tddium spec'.

Use 'tddium spec --force' to test with only already-committed changes.
EOF
      NOT_INITIALIZED = "tddium must be initialized. Try 'tddium login' or 'tddium heroku'"
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
      INVALID_INVITATION = "
Your invitation token wasn't recognized. If you have a token,
make sure you enter it correctly.

If you want an invite, visit this URL to sign up:

http://www.tddium.com/
"
      NO_USER_DATA_FILE = "User data file '%s' does not exist"
      NO_MATCHING_FILES = "No files match '%s'"
      PASSWORD_ERROR = "Error changing password: %s"
      HEROKU_MISCONFIGURED = "There was an error linking your Heroku account to Tddium: %s"
      module Heroku
        NOT_FOUND = "heroku command not found.  Make sure the latest heroku gem is installed.\nOutput of `gem list heroku`:\n%s"
        NOT_ADDED =<<EOF;
It looks like you haven't enabled the tddium add-on for the default app.
Add it using 'heroku addons:add tddium'

If you've already enabled the addon for a specific app, try running:

   $ tddium heroku --app <your app name>'

EOF
        INVALID_FORMAT = "The 'heroku -s' command output a format we didn't recognize.  Make sure you're running the latest version of the heroku gem"
        NOT_LOGGED_IN = "Log in to your heroku account first using 'heroku login'"
        APP_NOT_FOUND = "The app '%s' is not recognized by Heroku"
      end
      ADD_MEMBER_ERROR = "Error adding %s: %s"
      REMOVE_MEMBER_ERROR = "Error removing %s: %s"
      ACTIVATE_LOGGED_IN = "You are logged in.  Use 'tddium account' for account information"
      USE_ACTIVATE = "Use 'tddium activate' to accept an invitation token"
    end
  end

  module DisplayedAttributes
    SUITE = %w{repo_name branch test_pattern
               ruby_version bundler_version rubygems_version
               test_scripts test_executions git_repo_uri}
    TEST_EXECUTION = %w{start_time end_time test_execution_stats report}
  end
end
