=begin
Copyright (c) 2011 tddium.com All Rights Reserved
=end

#
# tddium support methods
#
#

require 'rubygems'
require 'highline/import'
require 'yaml'

ALREADY_CONFIGURED =<<'EOF'

tddium has already been initialized.

(settings are in %s)

Use 'tddium config:reset' to clear configuration, and then run 'tddium config:init' again.
EOF


CONFIG_FILE_PATH = File.expand_path('~/.tddium')

def write_config(config)
  File.open(CONFIG_FILE_PATH, 'w', 0600) do |f|
    YAML.dump(config, f)
  end
end

def init_task
  if File.exists?(CONFIG_FILE_PATH) then
    puts ALREADY_CONFIGURED % CONFIG_FILE_PATH
  else
    conf = {}
    conf[:aws_key] = ask('Enter AWS Access Key: ')
    conf[:aws_secret] = ask('Enter AWS Secret: ')
    conf[:test_pattern] = ask('Enter filepattern for tests: ') { |q|
      q.default='**/*_spec.rb'
    }
    conf[:key_directory] = ask('Enter directory for secret key(s): ') { |q|
      q.default='spec/secret'
    }
    conf[:key_name] = ask('Enter secret key name (excluding .pem suffix): ') { |q|
      q.default='sg-keypair'
    }
    conf[:result_directory] = ask('Enter directory for result reports: ') { |q|
      q.default='results'
    }
    conf[:server_tag] = ask("(optional) Enter tag=value to give instances: ") 
    conf[:ssh_tunnel] = ask("Create ssh tunnel to hub at localhost:4444:") { |q|
      q.default=false
    }

    write_config conf
  end
end

def read_config
  defaults = {
    :aws_key => nil,
    :aws_secret => nil,
    :test_pattern => '**/*_test.rb',
    :key_name => nil,
    :key_directory => nil,
    :result_directory => 'results',
    :ssh_tunnel => false,
  }

  if File.exists?(CONFIG_FILE_PATH) then
    file_conf = YAML.load(File.read(CONFIG_FILE_PATH))
  else
    file_conf = {}
  end
  defaults.merge(file_conf)
end

# If the config file isn't YAML -- doesn't start with '---', convert it into
# YAML.
def convert_old_config
  oldpath = CONFIG_FILE_PATH + '.old'
  FileUtils.rm_f oldpath

  old_data = File.readlines(CONFIG_FILE_PATH)[0]
  unless old_data.match /^---/ then
    oldconf = read_old_config

    FileUtils.mv CONFIG_FILE_PATH, oldpath

    write_config oldconf
  end
end

#
def read_old_config(filename=CONFIG_FILE_PATH)
  conf = {
    :aws_key => nil,
    :aws_secret => nil,
    :test_pattern => '**/*_test.rb',
    :key_name => nil,
    :key_directory => nil,
    :result_directory => 'results',
    :ssh_tunnel => false,
  }
  if File.exists?(filename) then
    File.open(filename) do |f|
      f.each do |line|
        key, val = line.split(': ')
        if !key.nil? && !val.nil? then
          conf[key.to_sym] = val.chomp
        end
      end
    end
  end
  conf
end
  
# Compute the name of the ssh private key file from configured parameters
def key_file_name(config)
  if config[:key_name].nil? || config[:key_directory].nil?
    return nil
  end

  File.join(config[:key_directory], "#{config[:key_name]}.pem")
end

def get_keyfile
  conf = read_config
  key_file = key_file_name(conf)
  if key_file.nil?
    return nil
  elsif !File.exists?(key_file)
    STDERR.puts "No key file #{key_file} present"
    return nil
  elsif (File.stat(key_file).mode & "77".to_i(8) != 0)
    mode =File.stat(key_file).mode 
    STDERR.puts "Keyfile has wrong perms: #{mode.to_s}. should be x00"
    return nil
  else
    return key_file
  end
end
