# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

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
        say e.message if show_error
        raise e
      end
      result
    end

    def get_current_id(scope)
      case scope
      when "suite"
        current_suite_id
      when "account"
        current_account_id
      else
        raise "unrecognized scope"
      end
    end

    def current_account_id
      user_details = user_logged_in?(true, false)
      return user_details ? user_details["account_id"] : nil
    end

    def env_path(scope, key=nil)
      path = "/#{scope}s/#{get_current_id(scope)}/env"
      path += "/#{key}" if key
      return path
    end

    def get_config_key(scope, key=nil)
      path = env_path(scope, key)
      result = call_api(:get, path)
      return result
    end

    def set_config_key(scope, key, value)
      path = env_path(scope)
      result = call_api(:post, path, :env=>{key=>value})
      return result
    end

    def delete_config_key(scope, key)
      path = env_path(scope, key)
      result = call_api(:delete, path)
      return result
    end

    def get_user(api_key=nil)
      result = call_api(:get, Api::Path::USERS, {}, api_key, false) rescue nil
      return result && result['user']
    end

    def set_user(params)
      new_user = call_api(:post, Api::Path::USERS, {:user => params}, false, false)
      return new_user
    end

    def update_user(user_id, params, api_key=nil)
      result = call_api(:put, "#{Api::Path::USERS}/#{user_id}/", params, api_key, false)
      return result
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
      result = @api_config.get_api_key

      global_api_key = @api_config.get_api_key(:global => true)
      repo_api_key = @api_config.get_api_key(:repo => true)

      if (global_api_key && global_api_key != repo_api_key && message)
        say Text::Error::INVALID_CREDENTIALS
        return
      end

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
      return result['memberships']|| []
    end

    def set_memberships(params={})
      result = call_api(:post, Api::Path::MEMBERSHIPS, params)
      return result['memberships']|| []
    end

    def delete_memberships(email, params={})
      result = call_api(:delete, "#{Api::Path::MEMBERSHIPS}/#{email}", params)
      return result
    end

    def get_usage(params={})
      result = call_api(:get, Api::Path::ACCOUNT_USAGE)
      return result['usage'] || []
    end

    def get_keys(params={})
      result = call_api(:get, Api::Path::KEYS)
      return result['keys']|| []
    end

    def set_keys(params)
      result = call_api(:post, Api::Path::KEYS, params)
      return result
    end

    def delete_keys(name, params={})
      result = call_api(:delete, "#{Api::Path::KEYS}/#{name}", params)
      return result
    end

    def current_suite_id
      branch = Tddium::Git.git_current_branch
      id = @api_config.get_branch(branch, 'id')
      return id
    end

    def current_suite_options
      branch = Tddium::Git.git_current_branch
      options = @api_config.get_branch(branch, 'options')
      return options
    end

    def get_suites(params={})
      current_suites = call_api(:get, Api::Path::SUITES, params)
      current_suites ||= {}
      return current_suites['suites'] || []
    end

    def get_suite_by_id(id, params={})
      current_suites = call_api(:get, "#{Api::Path::SUITES}/#{id}", params)
      current_suites ||= {}
      return current_suites['suite']
    end

    def create_suite(params)
      new_suite = call_api(:post, Api::Path::SUITES, {:suite => params})
      return new_suite["suite"]
    end

    def update_suite(id, params={})
      result = call_api(:put, "#{Api::Path::SUITES}/#{id}", params)
      return result
    end

    def get_sessions(params={})
      begin
        current_sessions = call_api(:get, Api::Path::SESSIONS, params)
      rescue TddiumClient::Error::Base
        current_sessions = []
      end
      return current_sessions['sessions']
    end

    def create_session
      new_session = call_api(:post, Api::Path::SESSIONS)
      return new_session['session']
    end

    def register_session(session_id, suite_id, test_pattern)
      call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::REGISTER_TEST_EXECUTIONS}", {:suite_id => suite_id, :test_pattern => test_pattern})
    end

    def start_session(session_id, params)
      result = call_api(:post, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::START_TEST_EXECUTIONS}", params)
      return result
    end

    def poll_session(session_id, params={})
      result = call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/#{Api::Path::TEST_EXECUTIONS}")
      return result
    end

    def check_session_done(session_id)
      result = call_api(:get, "#{Api::Path::SESSIONS}/#{session_id}/check_done")
      return result
    end
  end
end
