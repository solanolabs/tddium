# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumAPI
    include TddiumConstant

    def initialize(api_config, tddium_client)
      @api_config = api_config
      @tddium_client = tddium_client
    end

    def call_api(method, api_path, params = {}, api_key = nil, show_error = true)
      api_key ||= @api_config.get_api_key unless api_key == false

      begin
        result = @tddium_client.call_api(method, api_path, params, api_key)
      rescue TddiumClient::Error::UpgradeRequired => e
        abort e.message
      rescue TddiumClient::Error::Base => e
        say e.message.dup if show_error
        raise e
      end
      result
    end

    def get_single_account_id
      user_details = user_logged_in?(true, false)
      return nil unless user_details
      accounts = user_details["participating_accounts"]
      unless accounts.length == 1
        msg = "You are a member of more than one organization.\n"
        msg << "Please specify the organization you want to operate on with "
        msg << "'org:an_organization_name'.\n"
        accounts.each do |acct|
          msg << "  #{acct["account"]}\n"
        end
        raise msg
      end
      accounts.first["account_id"]
    end

    def get_account_id(acct_name)
      user_details = user_logged_in?(true, false)
      return nil unless user_details
      accts = user_details["participating_accounts"]
      acct = accts.select{|acct| acct["account"] == acct_name}.first
      if acct.nil?
        raise "You aren't a member of organization '%s'." % acct_name
      end
      acct["account_id"]
    end

    def env_path(scope, key=nil)
      path = ['']

      case scope
      when "suite"
        path << 'suites'
        path << current_suite_id
      when "account", "org"
        path << 'accounts'
        path << get_single_account_id
      when /\Aaccount:/
        path << 'accounts'
        path << get_account_id(scope.sub(/\Aaccount:/, ''))
      when /\Aorg:/
        path << 'accounts'
        path << get_account_id(scope.sub(/\Aorg:/, ''))
      else
        raise "Unrecognized scope. Use 'suite', 'org', or 'org:an_organization_name'."
      end

      path << 'env'
      path << key if key
      path.join('/')
    end

    def get_config_key(scope, key=nil)
      path = env_path(scope, key)
      call_api(:get, path)
    end

    def set_config_key(scope, key, value)
      path = env_path(scope)
      call_api(:post, path, :env=>{key=>value})
    end

    def delete_config_key(scope, key)
      path = env_path(scope, key)
      call_api(:delete, path)
    end

    def get_user(api_key=nil)
      result = call_api(:get, Api::Path::USERS, {}, api_key, false) rescue nil
      result && result['user']
    end

    def set_user(params)
      call_api(:post, Api::Path::USERS, {:user => params}, false, false)
    end

    def update_user(user_id, params, api_key=nil)
      call_api(:put, "#{Api::Path::USERS}/#{user_id}/", params, api_key, false)
    end

    def get_user_credentials(options = {})
      params = {}

      if options[:cli_token]
        params[:cli_token] = options[:cli_token]
      elsif options[:invited]
        # prompt for email/invitation and password
        token = options[:invitation_token] || ask(Text::Prompt::INVITATION_TOKEN)
        params[:invitation_token] = token.strip
        params[:password] = options[:password] || HighLine.ask(Text::Prompt::NEW_PASSWORD) { |q| q.echo = "*" }
      else
        say Text::Warning::USE_PASSWORD_TOKEN
        params[:email] = options[:email] || HighLine.ask(Text::Prompt::EMAIL)
        params[:password] = options[:password] || HighLine.ask(Text::Prompt::PASSWORD) { |q| q.echo = "*" }
      end
      params
    end

    def login_user(options = {})
      # POST (email, password) to /users/sign_in to retrieve an API key
      begin
        user = options[:params]
        login_result = call_api(:post, Api::Path::SIGN_IN, {:user => user}, false, options[:show_error])
        @api_config.set_api_key(login_result["api_key"], user[:email])
      rescue TddiumClient::Error::Base => e
      end
      login_result
    end

    def user_logged_in?(active = true, message = false)
      global_api_key = @api_config.get_api_key(:global => true)
      repo_api_key = @api_config.get_api_key(:repo => true)

      if (global_api_key && repo_api_key && global_api_key != repo_api_key)
        say Text::Error::INVALID_CREDENTIALS if message
        return
      end

      result = repo_api_key || global_api_key

      if message && result.nil? then
        say Text::Error::NOT_INITIALIZED
      end

      if result && active
        u = get_user
        if message && u.nil?
          say Text::Error::INVALID_CREDENTIALS
        end
        u
      else
        result
      end
    end

    def get_memberships(params={})
      result = call_api(:get, Api::Path::MEMBERSHIPS)
      result['account_roles'] || []
    end

    def set_memberships(params={})
      result = call_api(:post, Api::Path::MEMBERSHIPS, params)
      result['memberships'] || []
    end

    def delete_memberships(email, params={})
      call_api(:delete, "#{Api::Path::MEMBERSHIPS}/#{email}", params)
    end

    def get_usage(params={})
      result = call_api(:get, Api::Path::ACCOUNT_USAGE_BY_ACCOUNT)
      result['usage'] || []
    end

    def get_keys(params={})
      result = call_api(:get, Api::Path::KEYS)
      result['keys']|| []
    end

    def set_keys(params)
      call_api(:post, Api::Path::KEYS, params)
    end

    def delete_keys(name, params={})
      call_api(:delete, "#{Api::Path::KEYS}/#{name}", params)
    end

    def current_branch
      @current_branch ||= Tddium::Git.git_current_branch
    end

    def current_suite_id
      # api_config.get_branch will query the server if there is no locally cached data
      @api_config.get_branch(current_branch, 'id')
    end

    def current_suite_options
      @api_config.get_branch(current_branch, 'options')
    end

    def default_branch
      @default_branch ||= Tddium::Git.git_default_branch
    end

    def default_suite_id
      # api_config.get_branch will query the server if there is no locally cached data
      @api_config.get_branch(default_branch, 'id')
    end

    def default_suite_options
      @api_config.get_branch(default_branch, 'options')
    end

    # suites/user_suites returns:
    # [                                                                               
    #   'account',
    #   'account_id',
    #   'branch',                                                                          
    #   'ci_ssh_pubkey', 
    #   'git_repo_uri', 
    #   'id', 
    #   'org_name', 
    #   'repo_name', 
    #   'repo_url'                                  
    # ]
    def get_suites(params={})
      current_suites = call_api(:get, "#{Api::Path::SUITES}/user_suites", params)
      current_suites ||= {}
      current_suites['suites'] || []
    end

    def get_suite_by_id(id, params={})
      current_suites = call_api(:get, "#{Api::Path::SUITES}/#{id}", params)
      current_suites ||= {}
      current_suites['suite']
    end

    def create_suite(params)
      account_id = params.delete(:account_id)
      new_suite = call_api(:post, Api::Path::SUITES, {:suite => params, :account_id => account_id})
      new_suite["suite"]
    end

    def update_suite(id, params={})
      call_api(:put, "#{Api::Path::SUITES}/#{id}", params)
    end

    def permanent_destroy_suite(id, params={})
      call_api(:delete, "#{Api::Path::SUITES}/#{id}/permanent_destroy", params)
    end

    def get_sessions(params={})
      begin
        call_api(:get, Api::Path::SESSIONS, params)['sessions']
      rescue TddiumClient::Error::Base
        []
      end
    end

    def create_session(suite_id, params = {})
      new_session = call_api(:post, Api::Path::SESSIONS, params.merge(:suite_id=>suite_id))
      new_session['session']
    end

    def update_session(session_id, params={})
      result = call_api(:put, "#{Api::Path::SESSIONS}/#{session_id}", params)
      result['session']
    end

    def register_session(session_id, suite_id, test_pattern)
      call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::REGISTER_TEST_EXECUTIONS}", {:suite_id => suite_id, :test_pattern => test_pattern})
    end

    def start_session(session_id, params)
      call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::START_TEST_EXECUTIONS}", params)
    end

    def stop_session(ls_id, params = {})
      call_api(:post, "#{Api::Path::SESSIONS}/#{ls_id}/stop", params)
    end

    def poll_session(session_id, params={})
      call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::TEST_EXECUTIONS}")
    end

    def query_session(session_id, params={})
      call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::QUERY_TEST_EXECUTIONS}")
    end

    def check_session_done(session_id)
      call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/check_done")
    end
  end
end
