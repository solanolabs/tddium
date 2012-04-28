# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "keys", "List SSH keys authorized with Tddium"
    def keys
      tddium_setup({:git => false})

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
      tddium_setup({:git => false})

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
          keydata = Tddium::Ssh.load_ssh_key(path, name)
        else
          say Text::Process::ADD_KEYS_GENERATE % name
          keydata = Tddium::Ssh.generate_keypair(name, output_dir)
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
      tddium_setup({:git => false})

      begin
        say Text::Process::REMOVE_KEYS % name
        result = call_api(:delete, "#{Api::Path::KEYS}/#{name}")
        say Text::Process::REMOVE_KEYS_DONE % name
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::REMOVE_KEYS_ERROR % name
      end
    end
  end
end  
