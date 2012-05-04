# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  module Git
    class << self
      include TddiumConstant

      def git_changes
        cmd = "(git ls-files --exclude-standard -d -m -t || echo GIT_FAILED) < /dev/null 2>&1"
        p = IO.popen(cmd)
        changes = false
        while line = p.gets do
          if line =~ /GIT_FAILED/
            warn(Text::Warning::GIT_UNABLE_TO_DETECT)
            return false
          end
          line = line.strip
          fields = line.split(/\s+/)
          status = fields[0]
          if status !~ /^\?/ then
            changes = true
            break
          end
        end
        return changes
      end
  
      def git_version_ok
        version = nil
        begin
          version_string = `git --version`
          m =  version_string.match(Dependency::VERSION_REGEXP)
          version = m[0] unless m.nil?
        rescue Errno
        rescue Exception
        end
        if version.nil? || version.empty? then
          exit_failure(Text::Error::GIT_NOT_FOUND)
        end
        version_parts = version.split(".")
        if version_parts[0].to_i < 1 ||
           version_parts[1].to_i < 7 then
          warn(Text::Warning::GIT_VERSION % version)
        end
      end
  
      def git_current_branch
        `git symbolic-ref HEAD`.gsub("\n", "").split("/")[2..-1].join("/")
      end
  
      def git_push
        say Text::Process::GIT_PUSH
        system("git push -f #{Config::REMOTE_NAME} #{git_current_branch}")
      end
  
      def git_repo?
        ok = system("test -d .git || git status > /dev/null 2>&1")
        return ok
      end
  
      def git_root
        root = `git rev-parse --show-toplevel 2>&1`
        if $?.exitstatus == 0 then
          root.chomp! if root
          return root
        end
        return Dir.pwd
      end
  
      def git_repo_name
        return File.basename(git_root)
      end
  
      def git_origin_url
        result = `(git config --get remote.origin.url || echo GIT_FAILED) 2>/dev/null`
        return nil if result =~ /GIT_FAILED/
        if result =~ /@/
          result.strip
        else
          nil
        end
      end
  
      def update_git_remote_and_push(git_repo_uri)
        unless `git remote show -n #{Config::REMOTE_NAME}` =~ /#{git_repo_uri}/
          `git remote rm #{Config::REMOTE_NAME} > /dev/null 2>&1`
          `git remote add #{Config::REMOTE_NAME} #{git_repo_uri}`
        end
        git_push
      end
    end
  end
end
