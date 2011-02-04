require 'tddium/config'
require 'digest/sha1'
require 'tddium_helper'
require 'ftools'

def prepare_task(args)
  args.with_defaults(:environment => "selenium")

  tests = find_test_files()
  puts "\t#{tests.size} test files"
  first = true

  tests.each do |test|
    prefix = SpecStorm::db_prefix_for(test)
    puts "Migrating another set of tables..."
    puts "Generating DB_PREFIX: #{test} -> #{prefix}"

    if first == true
      ["export DB_PREFIX=#{prefix}; rake db:drop RAILS_ENV=#{args.environment} --trace",
       "export DB_PREFIX=#{prefix}; rake db:create RAILS_ENV=#{args.environment} --trace"].each do |command|
        IO.popen( command ).close 
      end
    end
    
    ["export DB_PREFIX=#{prefix}; rake db:migrate RAILS_ENV=#{args.environment} --trace"].each do |cmd|
      IO.popen( cmd ).close
    end
    
    first = false
  end
end

def setup_task(args)
  args.with_defaults(:environment => "selenium")

  File.copy(File.join(RAILS_ROOT, 'config', 'environments', 'test.rb'),
            File.join(RAILS_ROOT, 'config', 'environments', "#{args.environment}.rb"))

  open(File.join(RAILS_ROOT, 'config', 'environments', "#{args.environment}.rb"), 'a') do |f|
    f.puts "\nmodule SpecStorm"
    f.puts "  USE_NAMESPACE_HACK = true"
    f.puts "end"
  end
end
