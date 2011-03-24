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
      puts "No gemsets named: #{GEMSETS.join(" or ")}"
      puts "To create gemsets run the following commands:"
      command = ""
      GEMSETS.each do |rvm|
        ruby_version, gemset = rvm.split("@")
        command << "rvm use #{ruby_version} && rvm gemset create #{gemset} && "
        command << "rvm use #{rvm} && gem install bundler --no-rdoc --no-ri && bundle && "
      end
      puts command << "rake spec:xruby"
    end
  end
end
