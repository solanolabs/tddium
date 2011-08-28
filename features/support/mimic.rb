# Copyright (c) 2011 Solano Labs All Rights Reserved

require 'mimic'
require 'timeout'
require 'daemons'
require 'httparty'

class MimicServer
  attr_reader :port

  def initialize(port)
    @port = port || 8080
    @pid_list = []
  end

  def start
    pid = Kernel.fork
    if pid.nil? then
      args = {:fork => false,
              :host => 'localhost',
              :port => @port,
              :remote_configuration_path => '/api'}
      Mimic.mimic(args) do
        [:INT, :TERM].each { |sig| trap(sig) { Kernel.exit!(0) } }
      end
      Kernel.exit!(0)
    end
    @pid_list.push(pid)
    wait
  end

  def stop
    @pid_list.each do |pid|
      Process.kill("TERM", pid)
    end
    @pid_list = []
  end

  def wait
    (0...5).each do |i|
      if ping then
        break
      end
      Kernel.sleep(0.1)
    end
  end

  def ping
    begin
      http = call_api(:get,  '/api/ping')
    rescue Exception, Timeout::Error
      return false
    end
    return http.code == 200
  end

  def clear
    http = call_api(:post,  '/api/clear')
    return http
  end

  def install(verb, path, body, headers = {})
    params = { 'path' => path, 'body' => body.to_json }.to_json
    http = call_api(:post,  "/api/#{verb}", params, headers)
    return http
  end

  def call_api(method, path, params = {}, headers = {})
    tries = 0
    retries = 7
    done = false
    while (tries <= retries) && !done
      begin
        http = HTTParty.send(method, "http://localhost:#{@port}#{path}",
                             :body => params, :headers => headers)
        done = true
      rescue SystemCallError
        Kernel.sleep(0.5)
      rescue Timeout::Error
        Kernel.sleep(0.5)
      ensure
        tries += 1
      end
    end
    raise Timeout::Error if tries > retries && retries >= 0
    return http
  end

  class << self
    def test
      mimic = MimicServer.start
      mimic.clear
      mimic.stop
    end

    def start(port=nil)
      return @server if @server
      @server = MimicServer.new(port)
      @server.start
      @server
    end

    def server
      @server
    end

    def clear
      @server.clear rescue nil
    end
  end
end

Before('@mimic') do
  @aruba_timeout_seconds = 10
  tid = ENV['TDDIUM_TID'] || 0
  MimicServer.start(8500+tid.to_i)
end

After('@mimic') do
  MimicServer.clear
end

at_exit do
  server = MimicServer.server
  server.stop if server
end
