=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require "rubygems"
require "thor"
require "httparty"
require "json"

#      Usage:
#
#      tddium suite    # Register the suite for this rails app, or manage its settings
#      tddium spec     # Run the test suite
#      tddium status   # Display information about this suite, and any open dev
#                      #   sessions
#
#      tddium login    # Log your unix user in to a tddium account
#      tddium logout   # Log out
#
#      tddium account  # View/Manage account information
#
#      tddium dev      # Enter "dev" mode, for single-test quick-turnaround debugging.
#      tddium stopdev  # Leave "dev" mode.
#
#      tddium clean    # Clean up test results, especially large objects like videos
#
#      tddium help     # Print this usage message

class Tddium < Thor
  API_HOST = "http://api.tddium.com"
  API_VERSION = "1"
  GIT_REMOTE_NAME = "tddium"
  GIT_REMOTE_SCHEME = "ssh"
  GIT_REMOTE_USER = "git"
  GIT_REMOTE_ABSOLUTE_PATH = "/home/git/repo"

  desc "suite", "Register the suite for this rails app, or manage its settings"
  method_option :ssh_key, :type => :string, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  method_option :name, :type => :string, :default => nil
  def suite
    # Require git initialization
    unless File.exists?(".git")
      say "git repo must be initialized. Try 'git init'."
      return
    end

    # Inputs for API call
    params = {}

    default_ssh_file = "~/.ssh/id_rsa.pub"
    ssh_file = options[:ssh_key] || ask("Enter your ssh key or press 'Return'. Using #{default_ssh_file} by default:")
    ssh_file = default_ssh_file if ssh_file.empty?
    params[:ssh_key] = File.open(File.expand_path(ssh_file)) {|file| file.read}

    default_test_pattern = "**/*_spec.rb"
    test_pattern = options[:test_pattern] || ask("Enter a test pattern or press 'Return'. Using #{default_test_pattern} by default:")
    params[:test_pattern] = test_pattern.empty? ? default_test_pattern : test_pattern

    default_suite_name = "#{File.basename(Dir.pwd)}/#{current_git_branch}"
    suite_name = options[:name] || ask("Enter a suite name or press 'Return'. Using '#{default_suite_name}' by default:")
    params[:suite_name] = suite_name.empty? ? default_suite_name : suite_name

    params[:ruby_version] = `ruby -v`.match(/^ruby ([\d\.]+)/)[1]

    http = HTTParty.post(tddium_uri("suites"), :body => {:suite => params})
    response = JSON.parse(http.body) rescue {}

    if http.success?
      if response["status"] == 0
        # Manage git
        `git remote rm #{GIT_REMOTE_NAME}`
        `git remote add #{GIT_REMOTE_NAME} #{tddium_git_repo_uri(params[:suite_name])}`
        `git push #{GIT_REMOTE_NAME} #{current_git_branch}`

        # Save the created suite
        File.open(".tddium", "w") do |file|
          file.write({current_git_branch => response["suite"]["id"]}.to_json)
        end
      else
        message = "An error occured: #{response["explanation"]}"
      end
    else
      message = "An error occured: #{http.response.header.msg}"
      message << " #{response["explanation"]}" if response["status"].to_i > 0
    end
    say message
  end

  private

  def tddium_uri(path, api_version = API_VERSION)
    URI.join(API_HOST, "#{api_version}/#{path}").to_s
  end

  def tddium_git_repo_uri(suite_name)
    repo_name = suite_name.split("/").first
    git_uri = URI.parse(API_HOST)
    git_uri.scheme = GIT_REMOTE_SCHEME
    git_uri.userinfo = GIT_REMOTE_USER
    git_uri.path = "#{GIT_REMOTE_ABSOLUTE_PATH}/#{repo_name}"
    git_uri.to_s
  end

  def current_git_branch
    @current_git_branch ||= File.basename(`git symbolic-ref HEAD`.gsub("\n", ""))
  end
end
