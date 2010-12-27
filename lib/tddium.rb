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
require 'logrotate'

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
    pattern = ask('Enter filepattern for tests: ') { |q|
      q.default='**/*_spec.rb'
    }
    key_directory = ask('Enter directory for secret key(s): ') { |q|
      q.default='spec/secret'
    }
    key_name = ask('Enter secret key name (excluding .pem suffix): ') { |q|
      q.default='sg-keypair'
    }
    result_directory = ask('Enter directory for result reports: ') { |q|
      q.default='results'
    }

    File.open(CONFIG_FILE_PATH, 'w', 0600) do |f|
      f.write <<EOF
aws_key: #{key}
aws_secret: #{secret}
test_pattern: #{pattern}
key_directory: #{key_directory}
key_name: #{key_name}
result_directory: #{result_directory}
EOF
    end
  end
end

def read_config
  conf = {
    :aws_key => nil,
    :aws_secret => nil,
    :test_pattern => '**/*_test.rb',
    :key_name => nil,
    :key_directory => nil,
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
  @tddium_session = rand(2**64-1).to_s(36)

  key_file = nil
  if !conf[:key_name].nil? && !conf[:key_directory].nil?
    key_file = File.join(conf[:key_directory], "#{conf[:key_name]}.pem")
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

  server.wait_for { ready? }
  server.reload

  puts "started instance #{server.id} #{server.dns_name} in group #{server.groups} with tags #{server.tags.inspect}"

  uri = URI.parse("http://#{server.dns_name}:4444/console")
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
    system "ssh -i #{key_file} ec2-user@#{server.dns_name} 'sudo chmod 644 /var/log/messages'"
  else
    # TODO: Remove when /var/log/messages bug is fixed
    STDERR.puts "No key_file provided.  /var/log/messages may not be readable by ec2-user."
  end
  server
end

def result_directory
  
end

def stop_instance
  conf = read_config
  @ec2pool = Fog::AWS::Compute.new(:aws_access_key_id => conf[:aws_key],
                              :aws_secret_access_key => conf[:aws_secret])

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
