=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

#
# tddium support methods
#
#

require 'rubygems'
require 'highline/import'
require 'fog'
require 'net/http'
require 'uri'

ALREADY_CONFIGURED =<<'EOF'

tddium has already been initialized.

(settings are in %s)

Use 'tddium reset' to clear configuration, and then run 'tddium init' again.
EOF

CONFIG_FILE_PATH = File.expand_path('~/.tddium')

def init_task
  if File.exists?(CONFIG_FILE_PATH) then
    puts ALREADY_CONFIGURED % CONFIG_FILE_PATH
  else
    key = ask('Enter AWS Access Key: ')
    secret = ask('Enter AWS Secret: ')

    File.open(CONFIG_FILE_PATH, 'w', 0600) do |f|
      f.write <<EOF
aws_key: #{key}
aws_secret: #{secret}
EOF
    end
  end
end

def read_config
  conf = {
    :aws_key => nil,
    :aws_secret => nil
  }

  if File.exists?(CONFIG_FILE_PATH) then
    File.open(CONFIG_FILE_PATH) do |f|
      f.each do |line|
        key, val = line.split(': ')
        conf[key.to_sym] = val.chomp
      end
    end
  end
  conf
end

AMI_NAME = 'ami-b0a253d9'

def start_instance
  conf = read_config
  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                              :aws_secret_access_key => conf[:aws_secret])

  server = @ec2pool.servers.create(:flavor_id => 'm1.large',
                                   :groups => ['selenium-grid'],
                                   :image_id => AMI_NAME,
                                   :name => 'sg-server',
                                   :key_name => 'sg-keypair')
  server.wait_for { ready? }

  puts "started instance #{server.id} #{server.dns_name} in group #{server.groups}"

  uri = URI.parse("http://#{server.dns_name}:4444/console")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 60
  http.read_timeout = 60

  rc_up = false
  tries = 0
  while !rc_up && tries < 3
    begin
      http.request(Net::HTTP::Get.new(uri.request_uri))
      rc_up = true
    rescue Errno::ECONNREFUSED
    ensure
      tries += 1
    end
  end

  puts "Selenium Console:"
  puts "#{uri}"

  puts "ssh -i sg-keypair.pem ec2-user@#{server.dns_name}"
  server
end

def stop_instance
  conf = read_config
  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                              :aws_secret_access_key => conf[:aws_secret])
  @ec2pool.servers.each do |s|
    if s.image_id == AMI_NAME then
      puts "stopping instance #{s.id} #{s.dns_name}"
      s.destroy
    end
  end
end
