# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    include TddiumConstant

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
      say TddiumVersion::VERSION
    end

    private

    def tddium_client
      @tddium_client ||= TddiumClient::Client.new.tap do |c|
                           c.caller_version = "tddium-#{TddiumVersion::VERSION}"
                         end
    end

    def call_api(method, api_path, params = {}, api_key = nil, show_error = true)
      api_key =  tddium_settings(:fail_with_message => false)["api_key"] if tddium_settings(:fail_with_message => false) && api_key != false
      begin
        result = tddium_client.call_api(method, api_path, params, api_key)
      rescue TddiumClient::Error::UpgradeRequired => e
        exit_failure e.message
      rescue TddiumClient::Error::Base => e
        say e.message if show_error
        raise e
      end
      result
    end

    def tddium_deploy_key_file_name
      extension = ".#{environment}" unless environment == :production
      return File.join(git_root, ".tddium-deploy-key#{extension}")
    end

    def tddium_config
      return @tddium_yml if @tddium_yml

      config = begin
                 rawconfig = File.read(Config::CONFIG_PATH) rescue :notfound
                 rawconfig == :notfound ? {} : YAML.load(rawconfig)
               rescue
                 warn(Text::Warning::YAML_PARSE_FAILED % Config::CONFIG_PATH)
                 {}
               end
      return {} unless config.is_a?(Hash)

      config = config[:tddium] || config['tddium']
      config ||= {}
      @tddium_yml = config
      @tddium_yml
    end

    def configured_test_pattern
      pattern = tddium_config[:test_pattern] || tddium_config['test_pattern']

      return nil if pattern.nil? || pattern.empty?

      return pattern
    end

    def tddium_file_name
      extension = ".#{environment}" unless environment == :production
      return File.join(git_root, ".tddium#{extension}")
    end

    def tddium_settings_clear
      @tddium_settings = nil
    end

    def tddium_settings(options = {})
      options[:fail_with_message] = true unless options[:fail_with_message] == false
      if @tddium_settings.nil? || options[:force_reload]
        if File.exists?(tddium_file_name)
          settings_file = File.open(tddium_file_name) do |file|
            file.read
          end
          @tddium_settings = JSON.parse(settings_file) rescue nil
          say (Text::Error::INVALID_TDDIUM_FILE % environment) if @tddium_settings.nil? && options[:fail_with_message]
        else
          say Text::Error::NOT_INITIALIZED if options[:fail_with_message]
        end
      end
      @tddium_settings
    end

    def tddium_write_api_key(api_key)
      settings = tddium_settings(:fail_with_message => false) || {}
      File.open(tddium_file_name, "w") do |file|
        file.write(settings.merge({"api_key" => api_key}).to_json)
      end
      tddium_settings_clear
      tddium_write_gitignore
    end

    def tddium_write_suite(suite)
      suite_id = suite["id"]
      branches = tddium_settings["branches"] || {}
      branches.merge!({current_git_branch => {"id" => suite_id}})
      File.open(tddium_file_name, "w") do |file|
        file.write(tddium_settings.merge({"branches" => branches}).to_json)
      end
      File.open(tddium_deploy_key_file_name, "w") do |file|
        file.write(suite["ci_ssh_pubkey"])
      end
      tddium_settings_clear
      tddium_write_gitignore
    end

    def tddium_write_gitignore
      gitignore = File.join(git_root, Git::GITIGNORE)
      content = File.exists?(gitignore) ? File.read(gitignore) : ''
      unless content.include?(".tddium*\n")
        File.open(gitignore, "a") do |file|
          file.write(".tddium*\n")
        end
      end
      unless content.include?(".tddium\n")
        File.open(gitignore, "a") do |file|
          file.write(".tddium\n")
        end
      end
    end
  end
end
