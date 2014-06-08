# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def show_config_details(scope, config)
      if !config || config.length == 0
        say Text::Process::NO_CONFIG
      else
        say Text::Status::CONFIG_DETAILS % scope
        config.each do |k,v| 
          say "#{k}=#{v}"
        end
      end
      say Text::Process::CONFIG_EDIT_COMMANDS
    end

    def show_attributes(names_to_display, attributes)
      names_to_display.each do |attr|
        say Text::Status::ATTRIBUTE_DETAIL % [attr.gsub("_", " ").capitalize, attributes[attr]] if attributes[attr]
      end
    end

    def show_keys_details(keys)
      say Text::Status::KEYS_DETAILS
      if keys.length == 0
        say Text::Process::NO_KEYS
      else
        keys.each do |k| 
          if k["fingerprint"]
            say((" %-18.18s %s" % [k["name"], k["fingerprint"]]).rstrip)
          elsif k["pub"]
            fingerprint = ssh_key_fingerprint(k["pub"])
            if fingerprint then
              say((" %-18.18s %s" % [k["name"], fingerprint]).rstrip)
            else
              say((" %-18.18s" % k["name"]).rstrip)
            end
          else
            say((" %-18.18s" % k["name"]).rstrip)
          end
        end
      end
      say Text::Process::KEYS_EDIT_COMMANDS
    end

    def show_third_party_keys_details(user)
      say ERB.new(Text::Status::USER_THIRD_PARTY_KEY_DETAILS).result(binding)
    end

    def show_ssh_config(dir=nil)
      dir ||= ENV['TDDIUM_GEM_KEY_DIR']
      dir ||= Default::SSH_OUTPUT_DIR

      path = File.expand_path(File.join(dir, "identity.tddium.*"))

      Dir[path].reject{|fn| fn =~ /.pub$/}.each do |fn|
        say Text::Process::SSH_CONFIG % {:scm_host=>"git.solanolabs.com", :file=>fn}
      end
    end

    def format_usage(usage)
      "All tests: %.2f worker-hours  ($%.2f)" % [
        usage["hours"] || 0, usage["charge"] || 0]
    end

    def show_user_details(user)
      current_suites = @tddium_api.get_suites
      memberships = @tddium_api.get_memberships
      account_usage = @tddium_api.get_usage

      # Given the user is logged in, he should be able to
      # use "tddium account" to display information about his account:
      # Email address
      # Account creation date
      say ERB.new(Text::Status::USER_DETAILS).result(binding)

      # Use "all_accounts" here instead of "participating_accounts" -- these
      # are the accounts the user can administer.
      user["all_accounts"].each do |acct|
        id = acct['account_id'].to_i

        say ERB.new(Text::Status::ACCOUNT_DETAILS).result(binding)

        acct_suites = current_suites.select{|s| s['account_id'].to_i == id}
        if acct_suites.empty? then
          say '  ' + Text::Status::NO_SUITE
        else
          say '  ' + Text::Status::ALL_SUITES
          suites = acct_suites.sort_by{|s| "#{s['org_name']}/#{s['repo_name']}"}
          print_table suites.map {|suite|
            repo_name = suite['repo_name']
            if suite['org_name'] && suite['org_name'] != 'unknown'
              repo_name = suite['org_name'] + '/' + repo_name
            end
            [repo_name, suite['branch'], suite['repo_url'] || '']
          }, :indent => 4
        end

        # Uugh, json converts the keys to strings.
        usage = account_usage[id.to_s]
        if usage
          say "\n  Usage:"
          say "    Current month:  " + format_usage(usage["current_month"])
          say "    Last month:     " + format_usage(usage["last_month"])
        end

        acct_members = memberships.select{|m| m['account_id'].to_i == id}
        if acct_members.length > 1
          say "\n  " + Text::Status::ACCOUNT_MEMBERS
          print_table acct_members.map {|ar|
            [ar['user_handle'], ar['user_email'], ar['role']]
          }, :indent => 4
        end
      end

    rescue TddiumClient::Error::Base => e
      exit_failure e.message
    end
  end
end
