# Copyright (c) 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'fileutils'

module Tddium
  class TddiumCli < Thor
    desc "hg:mirror", "Construct local hg -> git mirror"
    method_option :noop, :type => :boolean, :default => false
    method_option :force, :type => :boolean, :default => false
    define_method "hg:mirror" do |*args|
      tddium_setup({:repo => true})

      if @scm.scm_name != 'hg' then
        exit_failure("Current repository does not appear to be using Mercurial")
      end

      if @scm.origin_url.nil? then
        exit_failure("Missing default path; please set default path in hgrc")
      end

      if File.exists?(@scm.mirror_path) then
        if !options[:force] then
          exit_failure("Mirror already exists; use --force to recreate")
        end
        if options[:noop] then
          exit_failure("Running in no-op mode; not removing existing mirror")
        end
        FileUtils.rm_rf(@scm.mirror_path)
      end

      FileUtils.mkdir_p(@scm.mirror_path)

      script_dir = File.join(File.dirname(__FILE__), '../..', 'script')
      script_dir = File.expand_path(script_dir)
      path = ENV['PATH'].split(':')
      path.unshift(script_dir)
      ENV['PATH'] = path.join(':')

      clone_command = "git clone hg::#{@scm.root} #{@scm.mirror_path}"
#      origin_command = "cd #{@scm.mirror_path} && git remote set-url origin #{@scm.origin_url}"

      if options[:noop] then
        puts "export PATH=#{ENV['PATH']}"
        puts clone_command
#        puts origin_command
      else
        Kernel.system(clone_command)
#        Kernel.system(origin_command)
      end
    end
  end
end
