# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'uri'
require 'shellwords'

module Tddium
  class Hg
    include TddiumConstant

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

    def changes?(options={})
      return Tddium::Hg.hg_changes?(:exclude=>".hgignore")
    end

    def push_latest(session_data, suite_details, options={})
      cmd = "hg push -f -b #{self.current_branch} "
      cmd += " #{suite_details['git_repo_uri']}"

      # git outputs something to stderr when it runs git push.
      # hg doesn't always ... so show the command that's being run and its
      # output to indicate progress.
      puts cmd
      puts `#{cmd}`
      return [0,1].include?( $?.exitstatus )
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
      result = `hg log --template='{node}\\n' #{id_from}..#{id_to}`
      result.split("\n").length
    end

    protected

    def latest_commit
      `hg log -f -l 1 --template='{node}\\n{desc|firstline}\\n{author|user}\\n{author|email}\\n{date}\\n{author|user}\\n{author|email}\\n{date}\\n\\n'`
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
        true
      end
    end
  end
end
