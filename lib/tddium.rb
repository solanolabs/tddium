=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

#
# tddium support methods
#
#

require 'rubygems'
require 'fog'
require 'net/http'
require 'uri'

require 'config'

AMI_NAME = 'ami-b0a253d9'

# Subprocess main body to create an ssh tunnel to hostname for selenium, binding
# remote:4444 to local:4444. Authenticate with the private key in key_file.
# 
# The ssh tunnel will auto-accept the remote host key.
def ssh_tunnel(hostname)
  ssh_up = false
  tries = 0
  while !ssh_up && tries < 3
    sleep 3
    ssh_up = remote_cmd(hostname, "-L 4444:#{hostname}:4444 -N")
    tries += 1
  end
end

def make_ssh_tunnel(key_file, server)
  $tunnel_pid = nil
  if !key_file.nil? then
    $tunnel_pid = Process.fork do
      ssh_tunnel(server.dns_name)
    end

    STDERR.puts "Created ssh tunnel to #{server.dns_name}:4444 at localhost:4444 [pid #{$tunnel_pid}]"
  end
end

def setup_environment(server)
  if !$tunnel_pid.nil?
    ENV['SELENIUM_RC_HOST'] = 'localhost'
  else
    ENV['SELENIUM_RC_HOST'] = server.dns_name
  end
  ENV['TDDIUM'] = '1'
end

DEV_SESSION_KEY='dev'

def checkstart_dev_instance
  conf = read_config
  dev_servers = session_instances(DEV_SESSION_KEY)
  if dev_servers.length > 0
    STDERR.puts "Using existing server #{dev_servers[0].dns_name}."
    setup_environment(dev_servers[0])
    return dev_servers[0]
  else
    STDERR.puts "Starting EC2 Instance"
    return start_instance(DEV_SESSION_KEY)
    sleep 30
  end
end

def remote_cmd(host, cmd)
  key_file = get_keyfile

  system("ssh -o 'StrictHostKeyChecking no' -i #{key_file} ec2-user@#{host} '#{cmd}'")
end

def remote_cp(host, remote_file, local_file)
  key_file = get_keyfile
  system("scp -o 'StrictHostKeyChecking no' -i #{key_file} ec2-user@#{host}:#{remote_file} #{local_file}")
end

# Start and setup an EC2 instance to run a selenium-grid node.  Set the
# tddium_session tag to session_key, if it's specified.
def start_instance(session_key=nil)
  conf = read_config

  if session_key.nil?
    @tddium_session = rand(2**64-1).to_s(36)
  else
    @tddium_session = session_key
  end

  key_file = get_keyfile

  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                                   :aws_secret_access_key => conf[:aws_secret])

  server = @ec2pool.servers.create(:flavor_id => 'm1.large',
                                   :groups => ['selenium-grid'],
                                   :image_id => AMI_NAME,
                                   :name => 'sg-server',
                                   :key_name => conf[:key_name])

  server.wait_for { ready? }
  server.reload

  @ec2pool.tags.create(:key => 'tddium_session', 
                       :value => @tddium_session,
                       :resource_id => server.id)

  if conf.include?(:server_tag) then
    server_tag = conf[:server_tag].split('=')

    @ec2pool.tags.create(:key => server_tag[0],
                         :value => server_tag[1],
                         :resource_id => server.id)
  end


  puts "started instance #{server.id} #{server.dns_name} in group #{server.groups} with tags #{server.tags.inspect}"

  if conf[:ssh_tunnel]
    make_ssh_tunnel(key_file, server)
  end

  setup_environment(server)

  uri = URI.parse("http://#{ENV['SELENIUM_RC_HOST']}:4444/console")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 60
  http.read_timeout = 60

  rc_up = false
  tries = 0
  while !rc_up && tries < 5
    begin
      http.request(Net::HTTP::Get.new(uri.request_uri))
      rc_up = true
    rescue Errno::ECONNREFUSED
      sleep 5
    rescue Timeout::Error
    ensure
      tries += 1
    end
  end
  raise "Couldn't connect to #{uri.request_uri}" unless rc_up

  puts "Selenium Console:"
  puts "#{uri}"

  if !key_file.nil?
    STDERR.puts "You can login via \"ssh -i #{key_file} ec2-user@#{server.dns_name}\""
    STDERR.puts "Making /var/log/messages world readable"
    remote_cmd(server.dns_name, "sudo chmod 644 /var/log/messages")
  else
    # TODO: Remove when /var/log/messages bug is fixed
    STDERR.puts "No key_file provided.  /var/log/messages may not be readable by ec2-user."
  end

  server
end

#
# Prepare the result directory, as specified by config[:result_directory].
#
# If the directory doesn't exist create it, and a latest subdirectory.
#
# If the latest subdirectory exists, rotate it and create a new empty latest.
#
def result_directory
  conf = read_config
  latest = File.join(conf[:result_directory], 'latest')

  if File.directory?(latest) then
    mtime = File.stat(latest).mtime.strftime("%Y%m%d-%H%M%S")
    archive = File.join(conf[:result_directory], mtime)
    FileUtils.mv(latest, archive)
  end
  FileUtils.mkdir_p latest
  latest
end

REPORT_FILENAME = "selenium_report.html"

def default_report_path
  File.join(read_config[:result_directory], 'latest', REPORT_FILENAME)
end

# Find all instances running the tddium AMI
def find_instances
  conf = read_config
  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                              :aws_secret_access_key => conf[:aws_secret])

  @ec2pool.servers.select{|s| s.image_id == AMI_NAME}
end

def session_instances(session_key)
  servers = find_instances
  if servers.nil?
    return nil
  else
    session_servers = []
    servers.each do |s|
      # in Fog 0.3.33, :filters is buggy and won't accept resourceId or resource_id
      tags = @ec2pool.tags(:filters => {:key => 'tddium_session'}).select{|t| t.resource_id == s.id}
      if tags.first and tags.first.value == session_key then
        STDERR.puts "selecting instance #{s.id} #{s.dns_name} from our session"
        session_servers << s
      else
        STDERR.puts "skipping instance #{s.id} #{s.dns_name} created in another session"
      end
    end
    return session_servers
  end
end

def stop_all_instances
  servers = find_instances
  servers.each do |s|
    STDERR.puts "stopping instance #{s.id} #{s.dns_name}"
    s.destroy
  end
end

def kill_tunnel
  if !$tunnel_pid.nil?
    Process.kill("TERM", $tunnel_pid)
    Process.waitpid($tunnel_pid)
    $tunnel_pid = nil
  end
end

# Stop the instance created by start_instance
def stop_instance(session_key=nil)
  conf = read_config

  kill_tunnel

  servers = session_instances(session_key ? session_key : @tddium_session)
  servers.each do |s|
    STDERR.puts "stopping instance #{s.id} #{s.dns_name} from our session"
    s.destroy
  end
  nil
end

def collect_syslog(target_directory='.')
  keyfile = get_keyfile
  if keyfile.nil?
    raise "No ssh keyfile configured.  Can't connect to remote"
  end
  instances = session_instances(@tddium_session ? @tddium_session : DEV_SESSION_KEY)
  instances.each do |inst|
    remote_cp(inst.dns_name, '/var/log/messages', 
              File.join(target_directory, "syslog.#{inst.dns_name}"))
  end
end
