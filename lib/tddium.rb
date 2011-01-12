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

def key_file_name(config)
  if config[:key_name].nil? || config[:key_directory].nil?
    return nil
  end

  File.join(config[:key_directory], "#{config[:key_name]}.pem")
end

def ssh_tunnel(key_file, hostname)
  ssh_up = false
  tries = 0
  while !ssh_up && tries < 3
    sleep 3
    ssh_up = system("ssh -o 'StrictHostKeyChecking no' -i #{key_file} ec2-user@#{hostname} -L 4444:#{hostname}:4444 -N")
    tries += 1
  end
end

def start_instance
  conf = read_config
  @tddium_session = rand(2**64-1).to_s(36)

  key_file = key_file_name(conf)
  if !key_file.nil?
    STDERR.puts "No key file #{key_file} with x00 permissions present" unless File.exists?(key_file) && (File.stat(key_file).mode & "77".to_i(8) == 0)
  end

  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                                   :aws_secret_access_key => conf[:aws_secret])

  server = @ec2pool.servers.create(:flavor_id => 'm1.large',
                                   :groups => ['selenium-grid'],
                                   :image_id => AMI_NAME,
                                   :name => 'sg-server',
                                   :key_name => conf[:key_name])

  @ec2pool.tags.create(:key => 'tddium_session', 
                       :value => @tddium_session,
                       :resource_id => server.id)

  if conf.include?(:server_tag) then
    server_tag = conf[:server_tag].split('=')

    @ec2pool.tags.create(:key => server_tag[0],
                         :value => server_tag[1],
                         :resource_id => server.id)
  end

  server.wait_for { ready? }
  server.reload

  puts "started instance #{server.id} #{server.dns_name} in group #{server.groups} with tags #{server.tags.inspect}"

  $tunnel_pid = nil
  if conf[:ssh_tunnel] && !key_file.nil? then
    $tunnel_pid = Process.fork do
      ssh_tunnel(key_file, server.dns_name)
    end

    STDERR.puts "Created ssh tunnel to #{server.dns_name}:4444 at localhost:4444 [pid #{$tunnel_pid}]"
    ENV['SELENIUM_RC_HOST'] = 'localhost'
  else
    ENV['SELENIUM_RC_HOST'] = server.dns_name
  end


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
    system "ssh -o 'StrictHostKeyChecking no' -i #{key_file} ec2-user@#{server.dns_name} 'sudo chmod 644 /var/log/messages'"
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

def stop_instance
  conf = read_config
  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                              :aws_secret_access_key => conf[:aws_secret])

  if !$tunnel_pid.nil?
    kill($tunnel_pid)
    waitpid($tunnel_pid)
    $tunnel_pid = nil
  end

  # TODO: The logic here is a bit convoluted now
  @ec2pool.servers.select{|s| s.image_id == AMI_NAME}.each do |s|
    # in Fog 0.3.33, :filters is buggy and won't accept resourceId or resource_id
    tags = @ec2pool.tags(:filters => {:key => 'tddium_session'}).select{|t| t.resource_id == s.id}
    if tags.first.value == @tddium_session then
      STDERR.puts "stopping instance #{s.id} #{s.dns_name} from our session"
      s.destroy
    else
      STDERR.puts "skipping instance #{s.id} #{s.dns_name} created in another session"
    end
  end
  nil
end
