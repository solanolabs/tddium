# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class Git
    include TddiumConstant

    def initialize
    end

    def configure
    end

    def scm_name
      return 'git'
    end

    def repo?
      if File.directory?('.git') then
        return true
      end
      ignore = `git status 2>&1`
      ok = $?.success?
      return ok
    end

    def root
      root = `git rev-parse --show-toplevel 2>&1`
      if $?.exitstatus == 0 then
        root.chomp! if root
        return root
      end
      return Dir.pwd
    end

    def mirror_path
      return nil
    end

    def repo_name
      return File.basename(self.root)
    end

    def origin_url
      result = `(git config --get remote.origin.url || echo GIT_FAILED) 2>/dev/null`
      return nil if result =~ /GIT_FAILED/
      result.strip
    end

    def ignore_path
      path = File.join(self.root, Config::GIT_IGNORE)
      return path
    end

    def current_branch
      `git symbolic-ref HEAD`.gsub("\n", "").split("/")[2..-1].join("/")
    end

    def default_branch
      `git remote show origin | grep HEAD | awk '{print $3}'`.gsub("\n", "")
    end

    def checkout(branch, options={})
      if !!options[:update] then
        `git fetch origin`
        return false if !$?.success?
      end

      cmd = "git checkout "
      if !!options[:force] then
        cmd += "-f "
      end
      cmd += Shellwords.shellescape(branch)
      `#{cmd}`
      return $?.success?
    end

    def changes?(options={})
      return Tddium::Git.git_changes?(:exclude=>".gitignore")
    end

    def push_latest(session_data, suite_details, options={})
      branch = options[:branch] || self.current_branch
      remote_branch = options[:remote_branch] || branch
      git_repo_uri = options[:git_repo_uri] || suite_details["git_repo_uri"]
      this_ref = (session_data['commit_data'] || {})['git_ref']
      refs = this_ref ? ["HEAD:#{this_ref}"] : []

      if options[:git_repo_origin_uri] then
        Tddium::Git.git_set_remotes(options[:git_repo_origin_uri], 'origin')
      end

      Tddium::Git.git_set_remotes(git_repo_uri)
      return Tddium::Git.git_push(branch, refs, remote_branch)
    end

    def current_commit
      `git rev-parse --verify HEAD`.strip
    end

    def commits
      commits = GitCommitLogParser.new(self.latest_commit).commits
      return commits
    end

    def number_of_commits(id_from, id_to)
      result = `git log --pretty='%H' #{id_from}..#{id_to}`
      result.split("\n").length
    end

    protected

    def latest_commit
      `git log --pretty='%H%n%s%n%aN%n%aE%n%at%n%cN%n%cE%n%ct%n' HEAD^..HEAD`
    end

    class << self
      include TddiumConstant

      def git_changes?(options={})
        options[:exclude] ||= []
        options[:exclude] = [options[:exclude]] unless options[:exclude].is_a?(Array)
        cmd = "(git status --porcelain -uno || echo GIT_FAILED) < /dev/null 2>&1"
        p = IO.popen(cmd)
        changes = false
        while line = p.gets do
          if line =~ /GIT_FAILED/
            warn(Text::Warning::SCM_UNABLE_TO_DETECT)
            return false
          end
          line = line.strip
          status, name = line.split(/\s+/)
          next if options[:exclude].include?(name)
          if status !~ /^\?/ then
            changes = true
            break
          end
        end
        return changes
      end

      def git_set_remotes(git_repo_uri, remote_name=nil)
        remote_name ||= Config::REMOTE_NAME

        unless `git remote show -n #{remote_name}` =~ /#{git_repo_uri}/
          `git remote rm #{remote_name} > /dev/null 2>&1`
          `git remote add #{remote_name} #{git_repo_uri.shellescape}`
        end
      end

      def git_push(this_branch, additional_refs=[], remote_branch=nil)
        say Text::Process::SCM_PUSH
        remote_branch ||= this_branch
        refs = ["#{this_branch}:#{remote_branch}"]
        refs += additional_refs
        refspec = refs.map(&:shellescape).join(" ")
        cmd = "git push -f #{Config::REMOTE_NAME} #{refspec}"
        say "Running '#{cmd}'"
        system(cmd)
      end

      def version_ok
        version = nil
        begin
          version_string = `git --version`
          m =  version_string.match(Dependency::VERSION_REGEXP)
          version = m[0] unless m.nil?
        rescue Errno
        rescue Exception
        end
        if version.nil? || version.empty? then
          abort Text::Error::SCM_NOT_FOUND
        end
        version_parts = version.split(".")
        if version_parts[0].to_i < 1 ||
           version_parts[1].to_i < 7 then
          warn(Text::Warning::GIT_VERSION % version)
        end
      end
    end
  end
end
