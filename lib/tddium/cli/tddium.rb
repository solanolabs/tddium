# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    include TddiumConstant

    def initialize(*args)
      super(*args)

      @tddium_client = TddiumClient::Client.new(:development, caller_version)
      @api_config = ApiConfig.new(@tddium_client)
      @repo_config = RepoConfig.new
      @tddium_api = TddiumAPI.new(@api_config, @tddium_client)

      # BOTCH: fugly
      @api_config.set_api(@tddium_api)
    end

    class_option :environment, :type => :string, :default => nil
    class_option :port, :type => :numeric, :default => nil

    require "tddium/cli/commands/account"
    require "tddium/cli/commands/activate"
    require "tddium/cli/commands/heroku"
    require "tddium/cli/commands/login"
    require "tddium/cli/commands/logout"
    require "tddium/cli/commands/password"
    require "tddium/cli/commands/spec"
    require "tddium/cli/commands/suite"
    require "tddium/cli/commands/status"
    require "tddium/cli/commands/keys"
    require "tddium/cli/commands/config"
    require "tddium/cli/commands/console"
    require "tddium/cli/commands/web"

    map "-v" => :version
    desc "version", "Print the tddium gem version"
    def version
      say VERSION
    end

    protected

    def caller_version
      "tddium-#{VERSION}"
    end

    def configured_test_pattern
      pattern = @repo_config[:test_pattern]

      return nil if pattern.nil? || pattern.empty?
      return pattern
    end

    def environment
      @tddium_client.environment.to_sym
    end

    def set_default_environment
      env = options[:environment] || ENV['TDDIUM_CLIENT_ENVIRONMENT']
      if env.nil? then
        @tddium_client.environment = :development
        if not File.exists?(@api_config.tddium_file_name) then
          @tddium_client.environment = :production
        end
      else
        @tddium_client.environment = env.to_sym
      end

      port = options[:port] || ENV['TDDIUM_CLIENT_PORT']
      @tddium_client.port = port.to_i if port
    end

    def tddium_setup(params={})
      params[:git] = true unless params.member?(:git)
      params[:login] = true unless params.member?(:login)
      params[:repo] = params[:repo] == true
      params[:suite] = params[:suite] == true

      $stdout.sync = true
      $stderr.sync = true

      set_shell
      set_default_environment
      Tddium::Git.git_version_ok if params[:git]

      @api_config.load_config

      user_details = @tddium_api.user_logged_in?(true, params[:login])
      if params[:login] && user_details.nil? then
        exit_failure
      end

      if params[:repo] && !Tddium::Git.git_repo? then
        say Text::Error::GIT_NOT_A_REPOSITORY
        exit_failure
      end

      if params[:suite] && !suite_for_current_branch? then
        say Test::Process::NO_CONFIGURED_SUITE
        exit_failure
      end
      return user_details
    end
  end
end
