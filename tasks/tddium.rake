#!/usr/bin/env ruby

=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'tddium'
require 'rubygems'
require 'rake'
require 'fileutils'

gem 'rspec', ">1.2.6"
require 'spec/rake/spectask'

gem "selenium-client", ">1.2.16"
require "selenium/rake/tasks"

namespace :tddium do
  namespace :config do
    task :init do
      init_task
    end

    task :reset do
      STDERR.puts "Old configuration:"
      STDERR.puts File.read(CONFIG_FILE_PATH)
      rm CONFIG_FILE_PATH, :force => true
    end
  end


  namespace :ss do
  end

  namespace :internal do
    Spec::Rake::SpecTask.new('sequential') do |t|
      conf = read_config
      
      t.pattern = @testname || conf[:test_pattern] || '**/*_spec.rb'

      STDERR.puts "Using test pattern #{t.pattern}"
      t.spec_opts = Proc.new do
        # Stub out result_path in case internal:sequential is run by itself
        @result_path ||= default_report_path
        s = []
        s << '--color'
        s << "--require 'rubygems,selenium/rspec/reporting/selenium_test_report_formatter'"
        s << "--format=Selenium::RSpec::SeleniumTestReportFormatter:#{@result_path}"
        s << "--format=progress"                
        s
      end
      t.fail_on_error = true
      t.verbose = true
    end

    desc "Launch selenium specs concurrently"
    task :parallel, :threads, :environment do |t,args|
      parallel_task(args)
    end
    
    task :start do
      start_instance
    end

    task :startstop do
      start_instance
      stop_instance
    end

    task :stop do
      stop_instance
    end

    task :stopall do
      stop_all_instances
    end

    task :collectlogs do
      collect_logs
    end

    desc "Setup initial selenium environment"
    task :setup, :environment do |t, args|
      setup_task(args)
    end

    desc "Prepare database with namespaces for concurrent rspec tests in path"
    task :prepare, :environment do |t,args|
      prepare_task(args)
    end

  end

  namespace :test do
    task :sequential do
      latest = result_directory
      begin
        puts "starting EC2 Instance"
        Rake::Task['internal:start'].execute
        $result_path = File.join(latest, REPORT_FILENAME)
        puts "Running tests. Results will be in #{$result_path}"
        sleep 30
        Rake::Task['internal:sequential'].execute
      ensure
        collect_syslog(latest)
        Rake::Task['internal:stop'].execute
      end
    end

    task :parallel do
      latest = result_directory
      begin
        puts "starting EC2 Instance"
        Rake::Task['internal:start'].execute
        @result_path = File.join(latest, REPORT_FILENAME)
        puts "Running tests. Results will be in #{@result_path}"
        sleep 30
        Rake::Task['internal:parallel'].execute
      ensure
        collect_syslog(latest)
        Rake::Task['internal:stop'].execute
      end
    end

    task :dev do
      latest = result_directory
      begin
        checkstart_dev_instance
        @result_path = File.join(latest, REPORT_FILENAME)
        puts "Running tests. Results will be in #{@result_path}"
        @testname = ARGV.shift
        Rake::Task['internal:sequential'].execute
      ensure
        collect_syslog(latest)
      end
    end

    task :stopdev do
      stop_instance('dev')
    end
  end
end
