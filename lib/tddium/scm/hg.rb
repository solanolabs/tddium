# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'uri'
require 'shellwords'

module Tddium
  class Hg
    include TddiumConstant

    def initialize
    end

    def configure
    end

    def scm_name
      return 'hg'
    end

    def repo?
      if File.directory?('.hg') then
        return true
      end
      ignore = `hg status 2>&1`
      ok = $?.success?
      return ok
    end

    def root
      root = `hg root`
      if $?.exitstatus == 0 then
        root.chomp! if root
        return root
      end
      return Dir.pwd
    end

    def mirror_path
      git_mirror_path = File.join(self.root, '.hg/git.tddium')
      git_mirror_path = File.expand_path(git_mirror_path)
      return git_mirror_path
    end

    def repo_name
      return File.basename(self.root)
    end

    def origin_url
      result = `(hg paths default || echo HG_FAILED) 2>/dev/null`
      return nil if result =~ /HG_FAILED/
      result.strip!
      u = URI.parse(result) rescue nil
      if u && u.host.nil? then
        warn(Text::Warning::HG_PATHS_DEFAULT_NOT_URI)
        return nil
      end
      return result
    end

    def ignore_path
      path = File.join(self.root, Config::HG_IGNORE)
      return path
    end

    def current_branch
      branch = `hg branch`
      branch.chomp!
      return branch
    end

    def default_branch
      # NOTE: not necessarily quite right in HG 2.1+ with a default bookmark
      return "default"
    end

    def checkout(branch, options={})
      if !!options[:update] then
        `hg pull`
        return false if !$?.success
      end

      cmd = "hg checkout "
      if !!options[:force] then
        cmd += "-C "
      end
      cmd += Shellwords.shellescape(branch)
      `#{cmd}`
      return $?.success?
    end

    def changes?(options={})
      return Tddium::Hg.hg_changes?(:exclude=>".hgignore")
    end

    def push_latest(session_data, suite_details, options={})
      rv = false
      pwd = Dir.pwd
      remote_branch = self.current_branch
      local_branch = "branches/#{self.current_branch}"
      begin
        if !File.exists?(self.mirror_path) then
          say Text::Warning::HG_GIT_MIRROR_MISSING
          raise
        end

        Tddium::Scripts.prepend_script_path

        Dir.chdir(self.mirror_path)
        git_scm = ::Tddium::Git.new
        git_scm.configure
        options = {force: true, update: true}
        if !git_scm.checkout(local_branch, options) then
          raise
        end
        git_repo_origin_uri = "hg::#{self.root}"
        options = {branch: local_branch, remote_branch: remote_branch,
                   git_repo_origin_uri: git_repo_origin_uri}
        rv = git_scm.push_latest(session_data, suite_details, options)
      rescue Exception => e
        rv = false
      ensure
        Dir.chdir(pwd)
      end

      return rv
    end

    def current_commit
      commit = `hg id -i`
      commit.chomp!
      return commit
    end

    def commits
      commits = HgCommitLogParser.new(self.latest_commit).commits
      return commits
    end

    def number_of_commits(id_from, id_to)
      result = `hg log --template='{node}\n' #{id_from}..#{id_to}`
      result.split("\n").length
    end

    protected

    def latest_commit
      `hg log -f -l 1 --template='{node}\n{desc|firstline}\n{author|user}\n{author|email}\n{date}\n{author|user}\n{author|email}\n{date}\n'`
    end

    class << self
      include TddiumConstant

      def hg_changes?(options={})
        options[:exclude] ||= []
        options[:exclude] = [options[:exclude]] unless options[:exclude].is_a?(Array)
        cmd = "(hg status -mardu || echo HG_FAILED) < /dev/null 2>&1"
        p = IO.popen(cmd)
        changes = false
        while line = p.gets do
          if line =~ /HG_FAILED/
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

      def hg_push(this_branch, additional_refs=[])
        raise "not implemented"
      end

      def version_ok
        version = nil
        begin
          version_string = `hg -q --version`
          m =  version_string.match(Dependency::VERSION_REGEXP)
          version = m[0] unless m.nil?
        rescue Errno
        rescue Exception
        end
        if version.nil? || version.empty? then
          abort Text::Error::SCM_NOT_FOUND
        end
        version_parts = version.split(".")
        if version_parts[0].to_i < 2 then
          warn(Text::Warning::HG_VERSION % version)
        end

        # BOTCH: currently have a git dependency, too
        ::Tddium::Git.version_ok
      end
    end
  end
end
