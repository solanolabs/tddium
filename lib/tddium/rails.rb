=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require 'tddium/config'
require 'digest/sha1'
require 'tddium_helper'
require 'ftools'

# Portions of this file derived from spec_storm, under the following license:
#
# Copyright (c) 2010 Sauce Labs Inc
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
