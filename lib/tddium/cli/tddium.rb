# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    include TddiumConstant

    attr_reader :scm
    attr_reader :user_details

    class_option :host, :type => :string, 
                        :default => ENV['TDDIUM_CLIENT_HOST'] || "ci.solanolabs.com",
                        :desc => "Solano CI app server hostname"

    class_option :port, :type => :numeric,
                        :default => (ENV['TDDIUM_CLIENT_PORT'].nil? ? nil : ENV['TDDIUM_CLIENT_PORT'].to_i),
                        :desc => "Solano CI app server port"

    class_option :proto, :type => :string,
                         :default => ENV['TDDIUM_CLIENT_PROTO'] || "https",
                         :desc => "API Protocol"

    class_option :insecure, :type => :boolean, 
                            :default => (ENV['TDDIUM_CLIENT_INSECURE'] != nil),
                            :desc => "Don't verify Solano CI app SSL server certificate"

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

      @scm = Tddium::SCM.configure

      @api_config = ApiConfig.new(@tddium_client, options[:host])
      @repo_config = RepoConfig.new
      @tddium_api = TddiumAPI.new(@api_config, @tddium_client, @scm)

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
    require "tddium/cli/commands/find_failing"
    require "tddium/cli/commands/spec"
    require "tddium/cli/commands/stop"
    require "tddium/cli/commands/suite"
    require "tddium/cli/commands/status"
    require "tddium/cli/commands/keys"
    require "tddium/cli/commands/config"
    require 'tddium/cli/commands/describe'
    require "tddium/cli/commands/web"
    require 'tddium/cli/commands/github'
    require 'tddium/cli/commands/hg'
    require 'tddium/cli/commands/set_params'

    map "-v" => :version
    desc "version", "Print the tddium gem version"
    def version
      say VERSION
    end

    # Thor has the wrong default behavior
    def self.exit_on_failure?
      return true
    end

    # Thor prints a confusing message for the "help" command in case an option
    # follows in the wrong order before the command.
    # This code patch overwrites this behavior and prints a better error message.
    # For Thor version >= 0.18.0, release 2013-03-26.
    if defined? no_commands
      no_commands do
        def invoke_command(command, *args)
          begin
            super
          rescue InvocationError
            if command.name == "help"
              exit_failure Text::Error::CANT_INVOKE_COMMAND
            else
              raise
            end
          end
        end
      end
    end

    protected

    def caller_version
      "tddium-#{VERSION}"
    end

    def configured_test_pattern
      pattern = @repo_config["test_pattern"]

      return nil if pattern.nil? || pattern.empty?
      return pattern
    end

    def configured_test_exclude_pattern
      pattern = @repo_config["test_exclude_pattern"]

      return nil if pattern.nil? || pattern.empty?
      return pattern
    end

    def tddium_setup(params={})
      params[:scm] = !params.member?(:scm) || params[:scm] == true
      params[:login] = true unless params.member?(:login)
      params[:repo] = params[:repo] == true
      params[:suite] = params[:suite] == true

      $stdout.sync = true
      $stderr.sync = true

      set_shell
      if params[:scm] then
        @scm.configure
      end

      @api_config.load_config

      user_details = @tddium_api.user_logged_in?(true, params[:login])
      if params[:login] && user_details.nil? then
        exit_failure
      end

      if params[:repo] && !@scm.repo? then
        say Text::Error::SCM_NOT_A_REPOSITORY
        exit_failure
      end

      if params[:suite] && !suite_for_current_branch? then
        exit_failure
      end

      @user_details = user_details
    end
  end
end
