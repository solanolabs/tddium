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
    desc "Initialize tddium configuration file"
    task :init do
      init_task
    end

    desc "Reset tddium configuration file"
    task :reset do
      reset_task
    end
  end

  namespace :internal do
    Spec::Rake::SpecTask.new('sequential') do |t|
      conf = read_config

      t.pattern = conf[:test_pattern] || '**/*_spec.rb'

      t.spec_opts = Proc.new do
        # Stub out result_path in case internal:sequential is run by itself
        @result_path ||= default_report_path
        opts = spec_opts(@result_path)
        opts
      end
      t.fail_on_error = true
      t.verbose = true
    end

    task :parallel, :threads, :environment do |t, args|
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
      collect_syslog
    end

    task :setup, :environment do |t, args|
      setup_task(args)
    end

    task :prepare, :environment do |t,args|
      prepare_task(args)
    end
  end

  desc "Sequentially run specs on EC2"
  task :sequential do
    latest = result_directory
    begin
      puts "starting EC2 Instance"
      Rake::Task['tddium:internal:start'].execute
      $result_path = File.join(latest, REPORT_FILENAME)
      puts "Running tests. Results will be in #{$result_path}"
      sleep 30
      Rake::Task['tddium:internal:sequential'].execute
    ensure
      collect_syslog(latest)
      Rake::Task['tddium:internal:stop'].execute
    end
  end

  desc "Run specs in parallel on EC2"
  task :parallel do
    latest = result_directory
    begin
      puts "starting EC2 Instance at #{Time.now.inspect}"
      Rake::Task['tddium:internal:start'].execute
      sleep 30
      args = Rake::TaskArguments.new([:result_directory], [latest])
      Rake::Task['tddium:internal:parallel'].execute(args)
    ensure
      collect_syslog(latest)
      Rake::Task['tddium:internal:stop'].execute
    end
  end

  desc "Run tests matching pattern, use running dev instance if possible"
  task :dev, :testpattern do |t, args|
    args.with_defaults(:testpattern => nil)
    latest = result_directory
    begin
      checkstart_dev_instance
      @result_path = File.join(latest, REPORT_FILENAME)
      puts "Running tests. Results will be in #{@result_path}"
      if args.testpattern
        puts "Selecting tests that match #{args.testpattern}"
        ENV['SPEC'] = args.testpattern
      end
      Rake::Task['tddium:internal:sequential'].execute
    ensure
      collect_syslog(latest)
    end
  end

  desc "Stop EC2 dev instance"
  task :stopdev do
    stop_instance('dev')
  end
end

module Rake
  class Task
    def clear_comment
      @comment = nil
    end
  end
end

Rake.application.tasks.select{|obj| /^tddium:internal/.match(obj.name)}.map{|obj| obj.clear_comment}

