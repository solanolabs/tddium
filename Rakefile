# Copyright (c) 2011 Solano Labs All Rights Reserved

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color"
end
task :default => :spec

namespace :spec do
  RUBY_VERSIONS = ["1.9.2-p180", "1.8.7-p334"]
  GEMSET = "tddium"
  desc "Runs the specs across Ruby 1.8.7 and 1.9.2"
  task :xruby do
    commands = []
    gemsets = []
    RUBY_VERSIONS.each do |ruby_version|
      current_gemset = "ruby-#{ruby_version}@#{GEMSET}"
      gemsets << current_gemset
      commands << "rvm use #{ruby_version}" << "gem install bundler" << "bundle" << "rvm gemset create #{GEMSET}" <<
                  "rvm use #{current_gemset}" << "gem install bundler --no-rdoc --no-ri" << "bundle"
    end
    puts ""
    puts "Attempting to run the specs across ruby #{RUBY_VERSIONS.join(" and ")}..."
    puts "If you get an error, try running the following commands to get your environment set up:"
    puts commands.join(" && ")
    puts ""
    Kernel.exec("rvm #{gemsets.join(",")} rake spec")
  end
end
