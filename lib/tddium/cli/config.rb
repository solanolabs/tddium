# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class RepoConfig
    include TddiumConstant

    def initialize
      @config = load_config
    end

    def [](key)
      return @config[key.to_sym] || @config[key.to_s]
    end

    def config_filename
      @config_filename
    end

    def load_config
      config = nil

      cfgfile = Config::CONFIG_PATHS.select{|fn| File.exists?(fn) }.first

      if cfgfile
        @config_filename = cfgfile
        begin
          rawconfig = File.read(cfgfile)
          if rawconfig && rawconfig !~ /\A\s*\z/ then
            config = YAML.load(rawconfig)
            config = config[:tddium] || config['tddium'] || Hash.new
          end
        rescue Exception => e
          warn(Text::Warning::YAML_PARSE_FAILED % cfgfile)
        end
      end

      config ||= Hash.new
      return config
    end
  end

  class ApiConfig
    include TddiumConstant

    # BOTCH: should be a state object rather than entire CLI object
    def initialize(tddium_client)
      @tddium_client = tddium_client
      @config = Hash.new
    end

    # BOTCH: fugly
    def set_api(tddium_api)
      @tddium_api = tddium_api
    end

    def logout
      remove_tddium_files
    end

    def get_branch(branch, var)
      val = fetch('branches', branch, var)
      return val unless val.nil?

      args = {:repo_name => Tddium::Git.git_repo_name}
      suites = @tddium_api.get_suites(args)
      suites.each do |ste|
        set_suite(ste)
      end

      return fetch('branches', branch, var)
    end

    def get_api_key(options = {})
      options.any? ? load_config(options)['api_key'] : @config['api_key']
    end

    def set_api_key(api_key, user)
      @config['api_key'] = api_key
    end

    def git_ready_sleep
      s = ENV["TDDIUM_GIT_READY_SLEEP"] || Default::GIT_READY_SLEEP
      s.to_f
    end

    def set_suite(suite)
      branch = suite['branch']
      return if branch.nil? || branch.empty?

      metadata = ['id', 'ci_ssh_pubkey'].inject({}) { |h, v| h[v] = suite[v]; h }

      branches = @config["branches"] || {}
      branches.merge!({branch => metadata})
      @config.merge!({"branches" => branches})
    end

    def load_config(options = {})
      global_config = load_config_from_file(:global)
      return global_config if options[:global]

      repo_config = load_config_from_file
      return repo_config if options[:repo]

      @config = global_config.merge(repo_config)
    end

    def write_config
      path = tddium_file_name(:global)
      File.open(path, File::CREAT|File::TRUNC|File::RDWR, 0600) do |file|
        config = Hash.new
        config['api_key'] = @config['api_key'] if @config.member?('api_key')
        file.write(config.to_json)
      end

      path = tddium_file_name(:repo)
      File.open(path, File::CREAT|File::TRUNC|File::RDWR, 0600) do |file|
        file.write(@config.to_json)
      end

      if Tddium::Git.git_repo? then
        branch = Tddium::Git.git_current_branch
        suite = @config['branches'][branch] rescue nil

        if suite then
          path = tddium_deploy_key_file_name
          File.open(path, File::CREAT|File::TRUNC|File::RDWR, 0644) do |file|
            file.write(suite["ci_ssh_pubkey"])
          end
        end
        write_gitignore		# BOTCH: no need to write every time
      end
    end

    def write_gitignore
      path = File.join(Tddium::Git.git_root, Config::GIT_IGNORE)
      content = File.exists?(path) ? File.read(path) : ''
      unless content.include?(".tddium*\n")
        File.open(path, File::CREAT|File::APPEND|File::RDWR, 0644) do |file|
          file.write(".tddium*\n")
        end
      end
    end

    def tddium_file_name(scope=:repo, kind='', root=nil)
      env = environment
      ext = env == :production ? '' : ".#{env}"

      case scope
      when :repo
        root ||= Tddium::Git.git_repo? ? Tddium::Git.git_root : Dir.pwd

      when :global
        root = ENV['HOME']
      end

      return File.join(root, ".tddium#{kind}#{ext}")
    end

    def tddium_deploy_key_file_name
      return tddium_file_name(:repo, '-deploy-key')
    end

    def environment
      @tddium_client.environment.to_sym
    end

    protected

    def fetch(*args)
      h = @config
      while !args.empty? do
        return nil unless h.is_a?(Hash)
        return nil unless h.member?(args.first)
        h = h[args.first]
        args.shift
      end
      return h
    end

    private

    def remove_tddium_files
      [tddium_file_name, tddium_file_name(:global)].each do |tddium_file_path|
        File.delete(tddium_file_path) if File.exists?(tddium_file_path)
      end
    end

    def load_config_from_file(tddium_file_type = :repo)
      path = tddium_file_name(tddium_file_type)
      File.exists?(path) ? (JSON.parse(File.read(path)) rescue {}) : {}
    end
  end
end
