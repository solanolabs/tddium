# Copyright (c) 2011 Solano Labs All Rights Reserved

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color"
end
task :default => :spec

namespace :spec do
  desc "Runs the specs across Ruby 1.8.7 and 1.9.2"
  task :xruby do
    GEMSETS = ["ruby-1.9.2-p180@tddium", "ruby-1.8.7-p302@tddium"]
    if GEMSETS.include?(`rvm-prompt`.chomp)
      Kernel.exec("rvm #{GEMSETS.join(",")} specs")
    else
      puts "No gemsets named: #{GEMSETS}"
      puts "To create gemsets run the following commands:"
      puts "rvm use 1.9.2; rvm gemset create tddium; rvm use 1.8.7; rvm gemset create tddium;"
      puts "rvm use ruby-1.8.7-p302@tddium; bundle;"
      puts "rvm use ruby-1.9.2-p180@tddium; bundle;"
    end
  end
end
