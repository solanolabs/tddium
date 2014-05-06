# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class Hg
    include TddiumConstant

    def initialize
    end

    def configure
    end

    def repo?
    end

    def root
    end

    def repo_name
    end

    def origin_url
    end

    def ignore_path
    end

    def current_branch
    end

    def default_branch
    end

    def changes?(options={})
    end

    def push_latest(session_data, suite_details)
      return false
    end

    def current_commit
    end

    def commits
    end

    def number_of_commits(id_from, id_to)
    end

    class << self
      include TddiumConstant

      def hg_changes?(options={})
      end

      def hg_push(additional_refs=[])
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
      end
    end
  end
end
