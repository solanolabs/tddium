=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require "rubygems"
require "thor"
require "highline/import"
require "json"
require "tddium_client"
require "base64"
require "erb"
require File.expand_path("../tddium/constant", __FILE__)
require File.expand_path("../tddium/version", __FILE__)
require File.expand_path("../tddium/heroku", __FILE__)

#      Usage:
#      tddium suite    # Register the suite for this rails app, or manage its settings
#      tddium spec     # Run the test suite
#      tddium status   # Display information about this suite, and any open dev sessions
#
#      tddium login    # Log your unix user in to a tddium account
#      tddium logout   # Log out
#
#      tddium account  # View/Manage account information
#      tddium password # Change password
#
#      tddium help     # Print this usage message

class TddiumError < Exception
  attr_reader :message

  def initialize(message)
    @message = message
  end
end

class Tddium < Thor
  include TddiumConstant
  
  class_option :environment, :type => :string, :default => nil
  class_option :port, :type => :numeric, :default => nil

  require "tddium/commands/account"
  require "tddium/commands/activate"
  require "tddium/commands/heroku"
  require "tddium/commands/login"
  require "tddium/commands/logout"
  require "tddium/commands/password"
  require "tddium/commands/spec"
  require "tddium/commands/suite"
  require "tddium/commands/status"

  map "-v" => :version
  desc "version", "Print the tddium gem version"
  def version
    say TddiumVersion::VERSION
  end

  private

  def call_api(method, api_path, params = {}, api_key = nil, show_error = true)
    api_key =  tddium_settings(:fail_with_message => false)["api_key"] if tddium_settings(:fail_with_message => false) && api_key != false
    begin
      result = tddium_client.call_api(method, api_path, params, api_key)
    rescue TddiumClient::Error::UpgradeRequired => e
      exit_failure e.message
    rescue TddiumClient::Error::Base => e
      say e.message if show_error
      raise e
    end
    result
  end

  def git_changes
    cmd = "(git ls-files --exclude-standard -d -m -t || echo GIT_FAILED) < /dev/null 2>&1"
    p = IO.popen(cmd)
    changes = false
    while line = p.gets do
      if line =~ /GIT_FAILED/
        warn(Text::Warning::GIT_UNABLE_TO_DETECT)
        return false
      end
      line = line.strip
      fields = line.split(/\s+/)
      status = fields[0]
      if status !~ /^\?/ then
        changes = true
        break
      end
    end
    return changes
  end

  def git_version_ok
    version = nil
    begin
      version_string = `git --version`
      m =  version_string.match(Dependency::VERSION_REGEXP)
      version = m[0] unless m.nil?
    rescue Errno
    rescue Exception
    end
    if version.nil? || version.empty? then
      exit_failure(Text::Error::GIT_NOT_FOUND)
    end
    version_parts = version.split(".")
    if version_parts[0].to_i < 1 ||
       version_parts[1].to_i < 7 then
      warn(Text::Warning::GIT_VERSION % version)
    end
  end

  def tool_version(tool)
    key = "#{tool}_version".to_sym
    result = tddium_config[key]

    if result
      say Text::Process::CONFIGURED_VERSION % [tool, result]
      return result
    end

    result = `#{tool} -v`.strip
    say Text::Process::DEPENDENCY_VERSION % [tool, result]
    result
  end

  def current_git_branch
    @current_git_branch ||= `git symbolic-ref HEAD`.gsub("\n", "").split("/")[2..-1].join("/")
  end

  def current_suite_id
    tddium_settings["branches"][current_git_branch]["id"] if tddium_settings["branches"] && tddium_settings["branches"][current_git_branch]
  end

  def current_suite_options
    if tddium_settings["branches"] && tddium_settings["branches"][current_git_branch]
      tddium_settings["branches"][current_git_branch]["options"]
    end || {}
  end

  def current_suite_path
    "#{Api::Path::SUITES}/#{current_suite_id}"
  end

  def display_attributes(names_to_display, attributes)
    names_to_display.each do |attr|
      say Text::Status::ATTRIBUTE_DETAIL % [attr.gsub("_", " ").capitalize, attributes[attr]] if attributes[attr]
    end
  end

  def environment
    tddium_client.environment.to_sym
  end

  def warn(msg='')
    STDERR.puts("WARNING: #{msg}")
  end

  def exit_failure(msg='')
    abort msg
  end

  def get_remembered_option(options, key, default, &block)
    remembered = false
    if options[key] != default
      result = options[key]
    elsif remembered = current_suite_options[key.to_s]
      result = remembered
      remembered = true
    else
      result = default
    end
    
    if result
      msg = Text::Process::USING_SPEC_OPTION[key] % result
      msg +=  Text::Process::REMEMBERED if remembered
      msg += "\n"
      say msg
      yield result if block_given?
    end
    result
  end

  def get_user
    call_api(:get, Api::Path::USERS, {}, nil, false) rescue nil
  end

  def get_user_credentials(options = {})
    params = {}
    # prompt for email/invitation and password
    if options[:invited]
      token = options[:invitation_token] || ask(Text::Prompt::INVITATION_TOKEN)
      params[:invitation_token] = token.strip
    else
      params[:email] = options[:email] || ask(Text::Prompt::EMAIL)
    end
    params[:password] = options[:password] || HighLine.ask(Text::Prompt::PASSWORD) { |q| q.echo = "*" }
    params
  end

  def git_push
    say Text::Process::GIT_PUSH
    system("git push -f #{Git::REMOTE_NAME} #{current_git_branch}")
  end

  def git_repo?
    unless system("test -d .git || git status > /dev/null 2>&1")
      message = Text::Error::GIT_NOT_INITIALIZED
      say message
    end
    message.nil?
  end

  def git_root
    root = `git rev-parse --show-toplevel 2>&1`
    if $?.exitstatus == 0 then
      root.chomp! if root
      return root
    end
    return Dir.pwd
  end

  def git_origin_url
    result = `(git config --get remote.origin.url || echo GIT_FAILED) 2>/dev/null`
    return nil if result =~ /GIT_FAILED/
    if result =~ /@/
      result.strip
    else
      nil
    end
  end

  def handle_heroku_user(options, heroku_config)
    api_key = heroku_config['TDDIUM_API_KEY']
    user = call_api(:get, Api::Path::USERS, {}, api_key, false) rescue nil
    exit_failure Text::Error::HEROKU_MISCONFIGURED % "Unrecognized user" unless user
    say Text::Process::HEROKU_WELCOME % user["user"]["email"]

    if user["user"]["heroku_needs_activation"] == true
      say Text::Process::HEROKU_ACTIVATE
      params = get_user_credentials(:email => heroku_config['TDDIUM_USER_NAME'])
      params.delete(:email)
      params[:password_confirmation] = HighLine.ask(Text::Prompt::PASSWORD_CONFIRMATION) { |q| q.echo = "*" }
      begin
        params[:user_git_pubkey] = prompt_ssh_key(options[:ssh_key])
      rescue TddiumError => e
        exit_failure e.message
      end

      begin
        user_id = user["user"]["id"]
        result = call_api(:put, "#{Api::Path::USERS}/#{user_id}/", {:user=>params, :heroku_activation=>true}, api_key)
      rescue TddiumClient::Error::API => e
        exit_failure Text::Error::HEROKU_MISCONFIGURED % e
      rescue TddiumClient::Error::Base => e
        exit_failure Text::Error::HEROKU_MISCONFIGURED % e
      end
    end
    
    write_api_key(user["user"]["api_key"])
    say Text::Status::HEROKU_CONFIG 
  end

  def login_user(options = {})
    # POST (email, password) to /users/sign_in to retrieve an API key
    begin
      login_result = call_api(:post, Api::Path::SIGN_IN, {:user => options[:params]}, false, options[:show_error])
      # On success, write the API key to "~/.tddium.<environment>"
      write_api_key(login_result["api_key"])
    rescue TddiumClient::Error::Base
    end
    login_result
  end

  def prompt(text, current_value, default_value)
    value = current_value || ask(text % default_value, :bold)
    value.empty? ? default_value : value
  end

  def prompt_ssh_key(current)
    # Prompt for ssh-key file
    ssh_file = prompt(Text::Prompt::SSH_KEY, options[:ssh_key_file], Default::SSH_FILE)

    begin
      data = File.open(File.expand_path(ssh_file)) {|file| file.read}
    rescue Errno::ENOENT => e
      raise TddiumError.new(Text::Error::INACCESSIBLE_SSH_PUBLIC_KEY % [ssh_file, e])
    end

    if data =~ /^-+BEGIN [DR]SA PRIVATE KEY-+/ then
      raise TddiumError.new(Text::Error::INVALID_SSH_PUBLIC_KEY % ssh_file)
    end
    if data !~ /^\s*ssh-(dss|rsa)/ then
      raise TddiumError.new(Text::Error::INVALID_SSH_PUBLIC_KEY % ssh_file)
    end
    data
  end

  def prompt_suite_params(options, params, current={})
    say Text::Process::DETECTED_BRANCH % params[:branch] if params[:branch]
    params[:ruby_version] = tool_version(:ruby)
    params[:bundler_version] = tool_version(:bundle)
    params[:rubygems_version] = tool_version(:gem)

    ask_or_update = lambda do |key, text, default|
      params[key] = prompt(text, options[key], current.fetch(key.to_s, default))
    end

    ask_or_update.call(:test_pattern, Text::Prompt::TEST_PATTERN, Default::SUITE_TEST_PATTERN)

    if current.size > 0 && current['ci_pull_url']
      say(Text::Process::SETUP_CI_EDIT)
    else
      say(Text::Process::SETUP_CI_FIRST_TIME % params[:test_pattern])
    end

    ask_or_update.call(:ci_pull_url, Text::Prompt::CI_PULL_URL, git_origin_url) 
    ask_or_update.call(:ci_push_url, Text::Prompt::CI_PUSH_URL, nil)

    if current.size > 0 && current['campfire_room']
      say(Text::Process::SETUP_CAMPFIRE_EDIT)
    else
      say(Text::Process::SETUP_CAMPFIRE_FIRST_TIME)
    end

    subdomain = ask_or_update.call(:campfire_subdomain, Text::Prompt::CAMPFIRE_SUBDOMAIN, nil)
    if !subdomain.nil? && subdomain != 'disable' then
      ask_or_update.call(:campfire_token, Text::Prompt::CAMPFIRE_TOKEN, nil)
      ask_or_update.call(:campfire_room, Text::Prompt::CAMPFIRE_ROOM, nil)
    end
  end

  def update_suite(suite, options)
    params = {}
    prompt_suite_params(options, params, suite)
    call_api(:put, "#{Api::Path::SUITES}/#{suite['id']}", params)
    say Text::Process::UPDATED_SUITE
  end

  def resolve_suite_name(options, params, default_suite_name)
    # XXX updates params
    existing_suite = nil
    use_existing_suite = false
    suite_name_resolved = false
    while !suite_name_resolved
      # Check to see if there is an existing suite
      current_suites = call_api(:get, Api::Path::SUITES, params)
      existing_suite = current_suites["suites"].first

      # Get the suite name
      current_suite_name = params[:repo_name]
      if existing_suite
        # Prompt for using existing suite (unless suite name is passed from command line) or entering new one
        params[:repo_name] = prompt(Text::Prompt::USE_EXISTING_SUITE % params[:branch], options[:name], current_suite_name)
        if options[:name] || params[:repo_name] == Text::Prompt::Response::YES
          # Use the existing suite, so assign the value back and exit the loop
          params[:repo_name] = current_suite_name
          use_existing_suite = true
          suite_name_resolved = true
        end
      elsif current_suite_name == default_suite_name
        # Prompt for using default suite name or entering new one
        params[:repo_name] = prompt(Text::Prompt::SUITE_NAME, options[:name], current_suite_name)
        suite_name_resolved = true if params[:repo_name] == default_suite_name
      else
        # Suite name does not exist yet and already prompted
        suite_name_resolved = true
      end
    end
    [use_existing_suite, existing_suite]
  end

  def set_shell
    if !$stdout.tty? || !$stderr.tty? then
      @shell = Thor::Shell::Basic.new
    end
  end

  def set_default_environment
    env = options[:environment] || ENV['TDDIUM_CLIENT_ENVIRONMENT']
    if env.nil?
      tddium_client.environment = :development
      tddium_client.environment = :production unless File.exists?(tddium_file_name)
    else
      tddium_client.environment = env.to_sym
    end

    port = options[:port] || ENV['TDDIUM_CLIENT_PORT']
    if port
      tddium_client.port = port.to_i
    end
  end

  def show_user_details(api_response)
    # Given the user is logged in, she should be able to use "tddium account" to display information about her account:
    # Email address
    # Account creation date
    user = api_response["user"]
    say ERB.new(Text::Status::USER_DETAILS).result(binding)

    current_suites = call_api(:get, Api::Path::SUITES)
    if current_suites["suites"].size == 0 then
      say Text::Status::NO_SUITE
    else
      say Text::Status::ALL_SUITES % current_suites["suites"].collect {|suite| "#{suite["repo_name"]}/#{suite["branch"]}"}.join(", ")
    end

    memberships = call_api(:get, Api::Path::MEMBERSHIPS)
    if memberships["memberships"].length > 1
      say Text::Status::ACCOUNT_MEMBERS
      say memberships["memberships"].collect{|x|x['display']}.join("\n")
      say "\n"
    end

    account_usage = call_api(:get, Api::Path::ACCOUNT_USAGE)
    say account_usage["usage"]
  rescue TddiumClient::Error::Base => e
    exit_failure e.message
  end

  def format_suite_details(suite)
    # Given an API response containing a "suite" key, compose a string with
    # important information about the suite
    details = ERB.new(Text::Status::SUITE_DETAILS).result(binding)
    details
  end

  def tddium_deploy_key_file_name
    extension = ".#{environment}" unless environment == :production
    return File.join(git_root, ".tddium-deploy-key#{extension}")
  end

  def suite_for_current_branch?
    unless current_suite_id
      message = Text::Error::NO_SUITE_EXISTS % current_git_branch
      say message
    end
    message.nil?
  end

  def tddium_client
    @tddium_client ||= begin
                         c = TddiumClient::Client.new
                         c.caller_version = "tddium-preview-#{TddiumVersion::VERSION}"
                         c
                       end
  end

  def tddium_config
    YAML.load(File.read(Config::CONFIG_PATH))[:tddium] rescue {}
  end

  def tddium_file_name
    extension = ".#{environment}" unless environment == :production
    return File.join(git_root, ".tddium#{extension}")
  end

  def tddium_settings(options = {})
    options[:fail_with_message] = true unless options[:fail_with_message] == false
    if @tddium_settings.nil? || options[:force_reload]
      if File.exists?(tddium_file_name)
        settings_file = File.open(tddium_file_name) do |file|
          file.read
        end
        @tddium_settings = JSON.parse(settings_file) rescue nil
        say (Text::Error::INVALID_TDDIUM_FILE % environment) if @tddium_settings.nil? && options[:fail_with_message]
      else
        say Text::Error::NOT_INITIALIZED if options[:fail_with_message]
      end
    end
    @tddium_settings
  end

  def update_git_remote_and_push(suite_details)
    git_repo_uri = suite_details["suite"]["git_repo_uri"]
    unless `git remote show -n #{Git::REMOTE_NAME}` =~ /#{git_repo_uri}/
      `git remote rm #{Git::REMOTE_NAME} > /dev/null 2>&1`
      `git remote add #{Git::REMOTE_NAME} #{git_repo_uri}`
    end
    git_push
  end

  def user_logged_in?(active = true, message = false)
    result = tddium_settings(:fail_with_message => message) && tddium_settings["api_key"]
    (result && active) ? get_user : result
  end

  def write_api_key(api_key)
    settings = tddium_settings(:fail_with_message => false) || {}
    File.open(tddium_file_name, "w") do |file|
      file.write(settings.merge({"api_key" => api_key}).to_json)
    end
    write_tddium_to_gitignore
  end

  def write_suite(suite, options = {})
    suite_id = suite["id"]
    branches = tddium_settings["branches"] || {}
    branches.merge!({current_git_branch => {"id" => suite_id, "options" => options}})
    File.open(tddium_file_name, "w") do |file|
      file.write(tddium_settings.merge({"branches" => branches}).to_json)
    end
    File.open(tddium_deploy_key_file_name, "w") do |file|
      file.write(suite["ci_ssh_pubkey"])
    end
    write_tddium_to_gitignore
  end

  def write_tddium_to_gitignore
    content = File.exists?(Git::GITIGNORE) ? File.read(Git::GITIGNORE) : ''
    unless content.include?(".tddium*\n")
      File.open(Git::GITIGNORE, "a") do |file|
        file.write(".tddium*\n")
      end
    end
  end
end
