# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    desc "keys", "List SSH keys authorized with Tddium"
    def keys
      set_shell
      set_default_environment
      user_details = user_logged_in?(true, true)
      exit_failure unless user_details

      begin
        keys_details = call_api(:get, Api::Path::KEYS)
        show_keys_details(keys_details)
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::LIST_KEYS_ERROR
      end
    end

    desc "keys:add [NAME]", "Authorize a keypair with Tddium; generate one if key is not specified"
    method_option :dir, :type=>:string, :default=>nil
    method_option :key, :type=>:string, :default=>nil
    define_method "keys:add" do |name|
      set_shell
      set_default_environment
      user_details = user_logged_in?(true, true)
      exit_failure unless user_details

      path = options[:key]

      output_dir = options[:dir] || ENV['TDDIUM_GEM_KEY_DIR'] || Default::SSH_OUTPUT_DIR

      begin
        keys_details = call_api(:get, Api::Path::KEYS)
        keys_details = keys_details["keys"] || []
        if keys_details.count{|x|x['name'] == name} > 0
          exit_failure Text::Error::ADD_KEYS_DUPLICATE % name
        end
        if path then
          say Text::Process::ADD_KEYS_ADD % name
          keydata = load_ssh_key(path, name)
        else
          say Text::Process::ADD_KEYS_GENERATE % name
          keydata = generate_keypair(name, output_dir)
        end
        result = call_api(:post, Api::Path::KEYS, :keys=>[keydata])
        if path then
          say Text::Process::ADD_KEYS_ADD_DONE % [name, result["git_server"] || Default::GIT_SERVER, path]
        else
          outfile = File.expand_path(File.join(output_dir, "identity.tddium.#{name}"))
          say Text::Process::ADD_KEYS_GENERATE_DONE % [name, result["git_server"] || Default::GIT_SERVER, outfile]
        end
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::ADD_KEYS_ERROR % name
      end
    end

    desc "keys:remove [NAME]", "Remove a key that was authorized with Tddium"
    define_method "keys:remove" do |name|
      set_shell
      set_default_environment
      user_details = user_logged_in?(true, true)
      exit_failure unless user_details
      begin
        say Text::Process::REMOVE_KEYS % name
        result = call_api(:delete, "#{Api::Path::KEYS}/#{name}")
        say Text::Process::REMOVE_KEYS_DONE % name
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::REMOVE_KEYS_ERROR % name
      end
    end

    private

      def show_keys_details(keys)
        keys = keys["keys"] || []
        say Text::Status::KEYS_DETAILS
        if keys.length == 0
          say Text::Process::NO_KEYS
        else
          keys.each do |k| 
            if k["fingerprint"]
              say((" %-18.18s %s" % [k["name"], k["fingerprint"]]).rstrip)
            else
              say((" %-18.18s" % k["name"]).rstrip)
            end
          end
        end
        say Text::Process::KEYS_EDIT_COMMANDS
      end

      def show_ssh_config(dir=nil)
        dir ||= ENV['TDDIUM_GEM_KEY_DIR']
        dir ||= Default::SSH_OUTPUT_DIR

        path = File.expand_path(File.join(dir, "identity.tddium.*"))

        Dir[path].reject{|fn| fn =~ /.pub$/}.each do |fn|
          say Text::Process::SSH_CONFIG % {:git=>"git.tddium.com", :file=>fn}
        end
      end
  end
end  
