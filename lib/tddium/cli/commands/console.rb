# Copyright (c) 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    desc "console <session>", "Connect to Tddium instance"
    method_option :user, :type => :string, :default => nil
    def console(id, *args)
      set_shell
      set_default_environment

      ssh_args = *args

      keys = []
      host = nil
      user = 'root'

      begin
        raw = id && id[0] == 'i'
        path = raw ? Api::Path::INSTANCES : Api::Path::SESSIONS
        path += "/#{id}/sshauth"

        result = call_api(:get, path, {})
        user = result["user"] unless raw
        host = result["host"]
        keys = result["keys"]

      rescue TddiumClient::Error::API => e
        exit_failure "Failed due to error: #{e.explanation}"
      rescue TddiumClient::Error::Base => e
        exit_failure "Failed due to error: #{e.message}"
      rescue RuntimeError => e
        exit_failure "Failed due to internal error: #{e.inspect} #{e.backtrace}"
      end

      known_hosts = keys.map { |key| "#{host} #{key}" }.join("\n")

      user = options[:user] if options[:user]
      known_hosts_file = Tempfile.new('tddium-console')
      known_hosts_file.puts(known_hosts)
      known_hosts_file.close

      cmd = "ssh -l #{user}"
      cmd += " -o 'UserKnownHostsFile #{known_hosts_file.path}' "
      cmd += " #{ssh_args.join(' ')}" unless ssh_args.empty?
      cmd += " #{host}"

      argv = Shellwords.shellsplit(cmd)
      Kernel.exec(*argv)
      #known_hosts_file.unlink
    end
  end
end
