# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    class RepoConfig
      include TddiumConstant

      def initialize
        @config = load_config
      end

      def [](key)
        return @config[key.to_sym] || @config[key.to_s]
      end

      def load_config
        config = nil

        if File.exists?(Config::CONFIG_PATH) then
          begin
            rawconfig = File.read(Config::CONFIG_PATH)
            config = YAML.load(rawconfig)
            config = config[:tddium] || config['tddium'] || Hash.new
          rescue
            warn(Text::Warning::YAML_PARSE_FAILED % Config::CONFIG_PATH)
          end
	end

	config ||= Hash.new
        return config
      end
    end

    class ApiConfig
      include TddiumConstant

      def initialize(tddium_client)
        @dirty = false
	@tddium_client = tddium_client
        @config = load_config
      end

      def valid?
        return !@config.nil?
      end

      def dirty?
        return @dirty == true
      end

      def dirty!
        @dirty = true
      end

      def [](key)
        return @config[key]
      end

      def []=(key, value)
        @dirty = true
        return @config[key] = value
      end

      def get_api_key
        return nil unless valid?
        return @config['api_key']
      end

      def set_api_key(api_key)
        @dirty = true
        @config['api_key'] = api_key
      end

      def set_suite(branch, suite)
        @dirty = true

        suite_id = suite["id"]
        branches = @config["branches"] || {}
        branches.merge!({branch => {"id" => suite_id}})
        @config.merge!({"branches" => branches})
      end

      def load_config(options={})
        path = tddium_file_name

        return unless File.exists?(path)

        data = File.read(path)
        config = JSON.parse(data) rescue nil

        if config.nil? && options[:fail_with_message] then
          say (Text::Error::INVALID_TDDIUM_FILE % environment)
        end
	return config
      end

      def write_config
        if @dirty then
          File.open(tddium_file_name, "w") do |file|
            file.write(@config.to_json)
          end
          File.open(tddium_deploy_key_file_name, "w") do |file|
            file.write(suite["ci_ssh_pubkey"])
          end
          write_gitignore	# BOTCH: no need to write every time
        end
        @dirty = false
      end

      def write_gitignore
        gitignore = File.join(Tddium::Git.git_root, Git::GITIGNORE)
        content = File.exists?(gitignore) ? File.read(gitignore) : ''
        unless content.include?(".tddium*\n")
          File.open(gitignore, "a") do |file|
            file.write(".tddium*\n")
          end
        end
      end

      def tddium_file_name(kind='')
        env = environment
        ext = env == :production ? '' : ".#{env}"
        return File.join(Tddium::Git.git_root, ".tddium#{kind}#{ext}")
      end

      def tddium_deploy_key_file_name
        return tddium_file_name('-deploy-key')
      end

      def environment
        @tddium_client.environment.to_sym
      end
    end
  end
end
