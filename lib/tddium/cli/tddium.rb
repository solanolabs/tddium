# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    include TddiumConstant

    attr_reader :user_details

    class_option :host, :type => :string, 
                        :default => ENV['TDDIUM_CLIENT_HOST'] || "api.tddium.com",
                        :desc => "Tddium app server hostname"

    class_option :port, :type => :numeric,
                        :default => (ENV['TDDIUM_CLIENT_PORT'].nil? ? nil : ENV['TDDIUM_CLIENT_PORT'].to_i),
                        :desc => "Tddium app server port"

    class_option :proto, :type => :string,
                         :default => ENV['TDDIUM_CLIENT_PROTO'] || "https",
                         :desc => "API Protocol"

    class_option :insecure, :type => :boolean, 
                            :default => (ENV['TDDIUM_CLIENT_INSECURE'] != nil),
                            :desc => "Don't verify Tddium app SSL server certificate"

    def initialize(*args)
      super(*args)

      # XXX TODO: read host from .tddium file, allow selecting which .tddium "profile" to use
      cli_opts = options[:insecure] ? { :insecure => true } : {}
      @tddium_client = TddiumClient::InternalClient.new(options[:host], 
                                                        options[:port], 
                                                        options[:proto], 
                                                        1, 
                                                        caller_version, 
                                                        cli_opts)


      @api_config = ApiConfig.new(@tddium_client, options[:host])
      @repo_config = RepoConfig.new
      @tddium_api = TddiumAPI.new(@api_config, @tddium_client)

      # BOTCH: fugly
      @api_config.set_api(@tddium_api)
    end


    require "tddium/cli/commands/account"
    require "tddium/cli/commands/activate"
    require "tddium/cli/commands/heroku"
    require "tddium/cli/commands/login"
    require "tddium/cli/commands/logout"
    require "tddium/cli/commands/password"
    require "tddium/cli/commands/rerun"
    require "tddium/cli/commands/spec"
    require "tddium/cli/commands/stop"
    require "tddium/cli/commands/suite"
    require "tddium/cli/commands/status"
    require "tddium/cli/commands/keys"
    require "tddium/cli/commands/config"
    require 'tddium/cli/commands/describe'
    require "tddium/cli/commands/web"

    map "-v" => :version
    desc "version", "Print the tddium gem version"
    def version
      say VERSION
    end

    # Thor has the wrong default behavior
    def self.exit_on_failure?
      return true
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

    def tddium_setup(params={})
      params[:git] = true unless params.member?(:git)
      params[:login] = true unless params.member?(:login)
      params[:repo] = params[:repo] == true
      params[:suite] = params[:suite] == true

      $stdout.sync = true
      $stderr.sync = true

      set_shell
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
        exit_failure
      end

      @user_details = user_details
    end
  end
end
