=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium
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

  desc "keys:add [NAME]", "Generate an SSH keypair and authorize it with Tddium"
  define_method "keys:add" do |name|
    set_shell
    set_default_environment
    user_details = user_logged_in?(true, true)
    exit_failure unless user_details

    begin
      keys_details = call_api(:get, Api::Path::KEYS)
      if keys_details["keys"].count{|x|x['name'] == name} > 0
        exit_failure Text::Error::ADD_KEYS_DUPLICATE % name
      end
      say Text::Process::ADD_KEYS % name
      keydata = generate_keypair(name)
      result = call_api(:post, Api::Path::KEYS, :keys=>[keydata])
      say Text::Process::ADD_KEYS_DONE % [name, name]
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
      keys = keys["keys"]
      say Text::Status::KEYS_DETAILS
      keys.each do |k| 
       say " %18.18s %s" % [k["name"], k["fingerprint"]]
      end
      say Text::Process::KEYS_EDIT_COMMANDS
    end
end

