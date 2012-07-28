# Copyright (c) 2012 Solano Labs All Rights Reserved

require 'json'
require 'fileutils'
require 'securerandom'
require 'tddium_client'

module Tddium
  class BuildAgent
    MAXIMUM_ATTACHMENT_SIZE = 16*1024*1024

    def initialize
    end

    # @return Boolean indicating whether or not we are running inside Tddium
    def tddium?
      return ENV.member?('TDDIUM')
    end

    # @return The current worker thread ID
    # @note Id is not unique across workers; there is no accessible GUID
    def thread_id
      return fetch_id('TDDIUM_TID')
    end

    # @return Current session ID
    def session_id
      return fetch_id('TDDIUM_SESSION_ID')
    end

    # @return Per-execution unique ID of currently running test
    def test_exec_id
      return fetch_id('TDDIUM_TEST_EXEC_ID')
    end

    # @return Tddium environment (batch, interactive, etc.)
    def environment
      env = ENV['TDDIUM_MODE'] || 'none'
      return env
    end

    # Status of build
    # @param which :current or :last
    # @return 'passed', 'failed', 'error', or 'unknown'
    def build_status(which=:current)
      status = 'unknown'
      case which
      when :current
        status = ENV['TDDIUM_BUILD_STATUS']
      when :last
        status = ENV['TDDIUM_LAST_BUILD_STATUS']
      end
      status ||= 'unknown'
      return status
    end

    def current_branch
      cmd = "cd #{ENV['TDDIUM_REPO_ROOT']} && git symbolic-ref HEAD"
      `#{cmd}`.gsub("\n", "").split("/")[2..-1].join("/")
    end

    # Attach a blob to the session -- excessive storage use is billable
    # @param data blob that is convertible into a string
    # @param metadata hash of metadata options
    # @note See attach_file for description of options
    def attach(data, metadata)
      if data.size > MAXIMUM_ATTACHMENT_SIZE then
        raise TddiumError.new("Data are too large to attach to session")
      end

      if !metadata.member?(:name) then
        guid = SecureRandom.hex(4)
        metadata[:name] = "user.#{guid}.dat"
      end

      guid = SecureRandom.hex(8)
      temp_path = File.join(ENV['HOME'], 'tmp', "attach-#{guid}.dat")
      File.open(temp_path, File::CREAT|File::TRUNC|File::RDWR, 0600) do |file|
        file.write(data)
        attach_file(temp_path, metadata)
      end
    end

    # Attach a blob to the session -- excessive storage use is billable
    # @param data blob that is convertible into a string
    # @param [Hash] metadata hash of metadata options
    # @option metadata [String] :name Override name of attachment
    # @option metadata [String] :exec_id Attach to named test execution
    def attach_file(path, metadata={})
      if !File.exists?(path) then
        raise Errno::ENOENT.new(path)
      end
      if File.new(path).size > MAXIMUM_ATTACHMENT_SIZE then
        raise TddiumError.new("Data are too large to attach to session")
      end
      name = metadata[:name] || File.basename(path)
      attach_path = attachment_path(name, metadata[:exec_id])
      FileUtils.cp(path, attach_path)
    end

    protected

    def fetch_id(name)
      return nil unless tddium? && ENV.member?(name)
      id = ENV[name]
      return id.to_i
    end

    # FUTURE: convert to call to internal agent API server
    # Unregistered and authenticated files will be ignored
    def attachment_path(name, exec_id=nil)
      path = File.join(ENV['HOME'], 'results', session_id.to_s)
      if exec_id.nil? then
        path = File.join(path, 'session', name)
      else
        path = File.join(path, exec_id.to_s, name)
      end
      return path
    end
  end
end
