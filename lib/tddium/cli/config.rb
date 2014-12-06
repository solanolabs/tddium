# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module ConfigHelper
  def hash_stringify_keys(h)
    case h
    when Hash
      Hash[ h.map { |k, v| [ k.to_s, hash_stringify_keys(v) ] } ]
    when Enumerable
      h.map { |v| hash_stringify_keys(v) }
    else
      h
    end
  end
end

module Tddium
  class RepoConfig
    include TddiumConstant
    include ConfigHelper

    def initialize
      @scm = Tddium::SCM.configure
      @config = load_config
    end

    def [](key)
      return @config[key.to_s]
    end

    def config_filename
      @config_filename
    end

    def load_config
      config = nil

      root = @scm.root
      cfgfile_pair = pick_config_pair(root, Config::CONFIG_PATHS)
      cfgfile_pair_depr = pick_config_pair(root, Config::CONFIG_PATHS_DEPRECATED)

      if cfgfile_pair && cfgfile_pair_depr then
        abort Text::Error::CONFIG_PATHS_COLLISION % [cfgfile_pair, cfgfile_pair_depr]
      end

      cfgfile_pair = cfgfile_pair_depr if cfgfile_pair.nil?

      if cfgfile_pair && cfgfile_pair.first then
        cfgfile = cfgfile_pair.first
        @config_filename = cfgfile_pair[1]
        begin
          rawconfig = File.read(cfgfile)
          if rawconfig && rawconfig !~ /\A\s*\z/ then
            config = YAML.load(rawconfig)
            config = hash_stringify_keys(config)
            config = config['solano'] || config['tddium'] || config
          end
        rescue Exception => e
          warn(Text::Warning::YAML_PARSE_FAILED % cfgfile)
        end
      end

      config ||= Hash.new
      return config
    end

    private

    def pick_config_pair(root, config_paths)
      files = config_paths.map { |fn| [ File.join(root, fn), fn ] }
      files.select { |p| File.exists?(p.first) }.first
    end
  end

  class ApiConfig
    include TddiumConstant

    # BOTCH: should be a state object rather than entire CLI object
    def initialize(tddium_client, host, cli_options)
      @scm = Tddium::SCM.configure
      @tddium_client = tddium_client
      @config = Hash.new
      @host = host
      @cli_options = cli_options
    end

    # BOTCH: fugly
    def set_api(tddium_api)
      @tddium_api = tddium_api
    end

    def logout
      remove_tddium_files
    end

    def populate_branches(branch)
      suites = @tddium_api.get_suites(:repo_url => @scm.origin_url, :branch=>branch)
      suites.each do |ste|
        set_suite(ste)
      end
    end

    def get_branch(branch, var, options={})
      if options['account'].nil? && @cli_options[:account] then
        options['account'] = @cli_options[:account]
      end

      val = fetch_branch(branch, var, options)
      return val unless val.nil?

      populate_branches(branch)

      return fetch_branch(branch, var, options)
    end

    def get_api_key(options = {})
      options.any? ? load_config(options)['api_key'] : @config['api_key']
    end

    def set_api_key(api_key, user)
      @config['api_key'] = api_key
    end

    def scm_ready_sleep
      s = ENV["TDDIUM_SCM_READY_SLEEP"] || Default::SCM_READY_SLEEP
      s.to_f
    end

    def set_suite(suite)
      id = suite['id']
      branch = suite['branch']
      return if id.nil? || branch.nil? || branch.empty?

      keys = %w(id branch account repo_id ci_ssh_pubkey)
      metadata = keys.inject({}) { |h, v| h[v] = suite[v]; h }

      branches = @config["branches"] || {}
      branches.merge!({id => metadata})
      @config.merge!({"branches" => branches})
    end

    def delete_suite(branch, account=nil)
      branches = @config["branches"] || {}
      branches.delete_if do |k, v|
        v['branch'] == branch && (account.nil? || v['account'] == account)
      end
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

      if @scm.repo? then
        branch = @scm.current_branch
        id = get_branch(branch, 'id', {})
        suite = @config['branches'][id] rescue nil

        if suite then
          path = tddium_deploy_key_file_name
          File.open(path, File::CREAT|File::TRUNC|File::RDWR, 0644) do |file|
            file.write(suite["ci_ssh_pubkey"])
          end
        end
        write_scm_ignore		# BOTCH: no need to write every time
      end
    end

    def write_scm_ignore
      path = @scm.ignore_path
      content = File.exists?(path) ? File.read(path) : ''
      unless content.include?(".tddium*\n")
        File.open(path, File::CREAT|File::APPEND|File::RDWR, 0644) do |file|
          file.write(".tddium*\n")
        end
      end
    end

    def tddium_file_name(scope=:repo, kind='', root=nil)
      ext = (@host == 'api.tddium.com' || @host == 'ci.solanolabs.com') ? '' : ".#{@host}"

      case scope
      when :repo
        root ||= @scm.repo? ? @scm.root : Dir.pwd

      when :global
        root = ENV['HOME']
      end

      return File.join(root, ".tddium#{kind}#{ext}")
    end

    def tddium_deploy_key_file_name
      return tddium_file_name(:repo, '-deploy-key')
    end

    protected

    def fetch_branch(branch, var, options)
      h = @config['branches']
      return nil unless h.is_a?(Hash)
      h.keys.sort.each do |id|
        data = h[id]
        next unless data.is_a?(Hash)
        branch_name = data['branch']
        next unless branch_name == branch
        if options.keys.all? { |k| data.member?(k) && data[k] == options[k] }
          return data[var]
        end
      end
      return nil
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
