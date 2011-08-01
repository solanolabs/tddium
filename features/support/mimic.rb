require 'mimic'
require 'timeout'
require 'daemons'
require 'httparty'

class MimicServer
  attr_reader :port

  def initialize
    @port = 8080
    @pid_dir = File.join(Dir.tmpdir, 'mimic')
    FileUtils.mkdir_p(@pid_dir)
  end

  def start
    options = {:ARGV => ['start'], :log_output => true, :dir_mode => :normal, :dir => @pid_dir}
    args = {:fork => false,
            :host => 'localhost',
            :port => @port,
            :remote_configuration_path => '/api'}
    @mimic_group = Daemons.run_proc("mimic", options) do
      Mimic.mimic(args) do
        [:INT, :TERM].each { |sig| trap(sig) { STDERR.puts "got sig!"; Kernel.exit!(0) } }
      end
    end
    @mimic_group.setup
    wait
  end

  def stop
    return nil unless @mimic_group
    @mimic_group.stop_all
    @mimic_group.find_applications(@pid_dir)
    @mimic_group.zap_all
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

    def start
      return @server if @server
      @server = MimicServer.new
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

if __FILE__ == $0 then
  MimicServer.test
end

Before('@mimic') do
  MimicServer.start
#  @aruba_io_wait_seconds = 4
end

After('@mimic') do
  MimicServer.clear
end

at_exit do
  server = MimicServer.server
  server.stop if server
end

MimicServer.start
