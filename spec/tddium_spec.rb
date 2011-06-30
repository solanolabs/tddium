=begin
#foo
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require 'spec_helper'

class EXIT_FAILURE_EXCEPTION < RuntimeError; end

describe Tddium do
  include FakeFS::SpecHelpers
  include TddiumSpecHelpers

  SAMPLE_API_KEY = "afb12412bdafe124124asfasfabebafeabwbawf1312342erbfasbb"
  SAMPLE_APP_NAME = "tddelicious"
  SAMPLE_BRANCH_NAME = "test"
  SAMPLE_BUNDLER_VERSION = "1.10.10"
  SAMPLE_DATE_TIME = "2011-03-11T08:43:02Z"
  SAMPLE_EMAIL = "someone@example.com"
  SAMPLE_FILE_PATH = "./my_user_file.png"
  SAMPLE_FILE_PATH2 = "./my_user_file2.png"
  SAMPLE_INVITATION_TOKEN = "TZce3NueiXp2lMTmaeRr"
  SAMPLE_GIT_REPO_URI = "ssh://git@api.tddium.com/home/git/repo/#{SAMPLE_APP_NAME}"
  SAMPLE_HEROKU_CONFIG = {"TDDIUM_API_KEY" => SAMPLE_API_KEY, "TDDIUM_USER_NAME" => SAMPLE_EMAIL}
  SAMPLE_LICENSE_TEXT = "LICENSE"
  SAMPLE_PASSWORD = "foobar"
  SAMPLE_NEW_PASSWORD = "foobar2"
  SAMPLE_REPORT_URL = "http://api.tddium.com/1/sessions/1/test_executions/report"
  SAMPLE_RUBYGEMS_VERSION = "1.3.7"
  SAMPLE_RUBY_VERSION = "1.8.7"
  SAMPLE_RECURLY_URL = "https://tddium.recurly.com/account/1"
  SAMPLE_SESSION_ID = 1
  SAMPLE_SUITE_ID = 1
  SAMPLE_USER_ID = 1
  DEFAULT_TEST_PATTERN = "**/*_spec.rb"
  SAMPLE_SUITE_PATTERN = "features/*.feature, spec/**/*_spec.rb"
  CUSTOM_TEST_PATTERN = "**/cat_spec.rb"
  SAMPLE_SUITE_RESPONSE = {"repo_name" => SAMPLE_APP_NAME,
                           "branch" => SAMPLE_BRANCH_NAME, 
                           "id" => SAMPLE_SUITE_ID, 
                           "ruby_version"=>SAMPLE_RUBY_VERSION,
                           "rubygems_version"=>SAMPLE_RUBYGEMS_VERSION,
                           "bundler_version"=>SAMPLE_BUNDLER_VERSION,
                           "git_repo_uri" => SAMPLE_GIT_REPO_URI,
                           "test_pattern" => SAMPLE_SUITE_PATTERN}
  SAMPLE_SUITES_RESPONSE = {"suites" => [SAMPLE_SUITE_RESPONSE]}
  SAMPLE_TDDIUM_CONFIG_FILE = ".tddium.test"
  SAMPLE_TEST_EXECUTION_STATS = "total 1, notstarted 0, started 1, passed 0, failed 0, pending 0, error 0", "start_time"
  SAMPLE_USER_RESPONSE = {"status"=>0, "user"=>
    { "id"=>SAMPLE_USER_ID, 
      "api_key" => SAMPLE_API_KEY, 
      "email" => SAMPLE_EMAIL, 
      "created_at" => SAMPLE_DATE_TIME, 
      "recurly_url" => SAMPLE_RECURLY_URL}}
  SAMPLE_SSH_PUBKEY = "ssh-rsa 1234567890"
  SAMPLE_HEROKU_USER_RESPONSE = {"user"=>
    { "id"=>SAMPLE_USER_ID, 
      "api_key" => SAMPLE_API_KEY, 
      "email" => SAMPLE_EMAIL, 
      "created_at" => SAMPLE_DATE_TIME, 
      "heroku_needs_activation" => true,
      "recurly_url" => SAMPLE_RECURLY_URL}}
  PASSWORD_ERROR_EXPLANATION = "bad confirmation"
  PASSWORD_ERROR_RESPONSE = {"status"=>1, "explanation"=> PASSWORD_ERROR_EXPLANATION}

  def call_api_should_receive(options = {})
    params = [options[:method] || anything, options[:path] || anything, options[:params] || anything, (options[:api_key] || options[:api_key] == false) ? options[:api_key] : anything]
    tddium_client.stub(:call_api).with(*params).and_raise(TddiumClient::Error::Base)
    tddium_client.should_receive(:call_api).with(*params)
  end

  def extract_options!(array, *option_keys)
    is_options = false
    option_keys.each do |option_key|
      is_options ||= array.last.include?(option_key.to_sym)
    end
    (array.last.is_a?(Hash) && is_options) ? array.pop : {}
  end

  def run(tddium, options = {:test_pattern => DEFAULT_TEST_PATTERN, :environment => "test"})
    method = example.example_group.ancestors.map(&:description)[-2][1..-1]
    send("run_#{method}", tddium, options)
  end

  [:suite, :spec, :status, :account, :login, :logout, :password, :heroku, :version].each do |method|
    def prep_params(method, params=nil)
      options = params.first || {}
      options[:environment] = "test" unless options.has_key?(:environment)
      options
    end

    define_method("run_#{method}") do |tddium, *params|
      options = prep_params(method, params)
      stub_exit_failure
      stub_cli_options(tddium, options)
      begin
        tddium.send(method)
      rescue EXIT_FAILURE_EXCEPTION
      end
    end

    define_method("#{method}_should_fail") do |tddium, *params|
      options = prep_params(method, params)
      stub_cli_options(tddium, options)
      tddium.stub(:exit_failure).and_raise(SystemExit)
      yield if block_given?
      expect { tddium.send(method) }.to raise_error(SystemExit)
    end

    define_method("#{method}_should_pass") do |tddium, *params|
      options = prep_params(method, params)
      stub_cli_options(tddium, options)
      tddium.stub(:exit_failure).and_raise(SystemExit)
      yield if block_given?
      expect { tddium.send(method) }.not_to raise_error
    end
  end

  def stub_bundler_version(tddium, version = SAMPLE_BUNDLER_VERSION)
    tddium.stub(:`).with("bundle -v").and_return("Bundler version #{version}")
  end

  def stub_call_api_response(method, path, *response)
    result = tddium_client.stub(:call_api).with(method, path, anything, anything)
    response = [{}] if response.empty?
    response_mocks = []
    response.each do |current_response|
      current_response["status"] ||= 0
      status = current_response["status"]
      if status == 0
        tddium_client_result = mock(TddiumClient::Result::API)
        response_mocks << tddium_client_result
      else
        tddium_client_result = mock(TddiumClient::Error::API)
        tddium_client_result.stub(:body => current_response.to_json,
                                    :code => 200,
                                    :response => mock(:header => mock(:msg => "OK")))
        result.and_raise(TddiumClient::Error::API.new(tddium_client_result))
      end
      current_response.each do |k, v|
        tddium_client_result.stub(:[]).with(k).and_return(v)
      end
    end
    result.and_return(*response_mocks) unless response_mocks.empty?
  end

  def stub_call_api_error(method, path, code=500, response="Server Error")
    result = tddium_client.stub(:call_api).with(method, path, anything, anything)
    http_response = mock(TddiumClient::Error::Server)
    http_response.stub(:body => nil,
                              :code => code,
                              :response => mock(:header => mock(:msg => response)))
    result.and_raise(TddiumClient::Error::Server.new(http_response))
  end

  def stub_cli_options(tddium, options = {})
    tddium.stub(:options).and_return(options)
  end

  def stub_config_file(options = {})
    params = {}
    params.merge!(:branches => (options[:branches].is_a?(Hash)) ? options[:branches] : {SAMPLE_BRANCH_NAME => {"id" => SAMPLE_SUITE_ID}}) if options[:branches]
    params.merge!(:api_key => (options[:api_key].is_a?(String)) ? options[:api_key] : SAMPLE_API_KEY) if options[:api_key]
    json = params.to_json unless params.empty?
    create_file(SAMPLE_TDDIUM_CONFIG_FILE, json)
  end

  def stub_default_suite_name
    Dir.stub(:pwd).and_return(SAMPLE_APP_NAME)
  end

  def stub_defaults
    tddium.stub(:say)
    tddium.stub(:`).and_raise("unstubbed command")
    tddium.stub(:system).and_raise("unstubbed command")
    stub_git_branch(tddium)
    stub_tddium_client
    stub_git_status(tddium)
    stub_git_config(tddium)
    stub_git_changes(tddium)
    stub_git_version_ok(tddium)
    create_file(File.join(".git", "something"), "something")
    create_file(Tddium::Git::GITIGNORE, "something")
  end

  def stub_git_branch(tddium, default_branch_name = SAMPLE_BRANCH_NAME)
    tddium.stub(:`).with("git symbolic-ref HEAD").and_return(default_branch_name)
  end

  def stub_git_status(tddium, result=true)
    tddium.stub(:system).with(/git status/).and_return(result)
  end

  def stub_git_changes(tddium, result=false)
    tddium.stub(:git_changes).and_return(result)
  end

  def stub_git_version_ok(tddium, result=false)
    tddium.stub(:git_version_ok).and_return(result)
  end

  def stub_git_config(tddium)
    tddium.stub(:`).with("git config --get remote.origin.url").and_return(SAMPLE_GIT_REPO_URI)
  end

  def stub_git_push(tddium, success = true)
    tddium.stub(:system).with(/^git push/).and_return(success)
  end

  def stub_git_remote(tddium, action = :show, success = true)
    git_response = success ? "some text that contains #{SAMPLE_GIT_REPO_URI}" : "some text that does not contain the git repo uri" if action == :show
    tddium.stub(:`).with(/^git remote #{action}/).and_return(git_response)
  end

  def stub_ruby_version(tddium, version = SAMPLE_RUBY_VERSION)
    tddium.stub(:`).with("ruby -v").and_return("ruby #{version} (2010-08-16 patchlevel 302) [i686-darwin10.5.0]")
  end

  def stub_rubygems_version(tddium, version = SAMPLE_RUBYGEMS_VERSION)
    tddium.stub(:`).with("gem -v").and_return(version)
  end

  def stub_sleep(tddium)
    tddium.stub(:sleep).with(Tddium::Default::SLEEP_TIME_BETWEEN_POLLS)
  end

  def stub_exit_failure
    tddium.stub(:exit_failure).and_raise(EXIT_FAILURE_EXCEPTION)
  end

  def stub_tddium_client
    TddiumClient::Client.stub(:new).and_return(tddium_client)
    tddium_client.stub(:environment).and_return("test")
    tddium_client.stub(:call_api) do |x,y,z,k|
      raise TddiumClient::Error::Base.new("unstubbed call_api(#{x.inspect},#{y.inspect},#{z.inspect},#{k.inspect})")
    end
  end

  let(:tddium) { Tddium.new }
  let(:tddium_client) { mock(TddiumClient).as_null_object }

  describe "changes not in git" do
    before(:each) do
    end

    it "should fail and exit if git is not found" do
      tddium.stub(:`).with('git --version').and_raise(Errno::ENOENT)
      tddium.should_receive(:exit_failure).with(Tddium::Text::Error::GIT_NOT_FOUND).and_raise("exit")
      lambda { tddium.send(:git_version_ok) }.should raise_error("exit")
    end

    it "should warn if git version is unsupported" do
      tddium.stub(:`).with('git --version').and_return("git version 1.6.2")
      tddium.should_receive(:warn).with(Tddium::Text::Warning::GIT_VERSION % "1.6.2").and_return(nil)
      tddium.send(:git_version_ok)
    end

    it "should warn if git version is unsupported" do
      tddium.stub(:`).with('git --version').and_return("git version 1.7.5")
      tddium.should_not_receive(:exit_failure)
      tddium.should_not_receive(:warn)
      tddium.send(:git_version_ok)
    end
  end

  describe "changes in git" do
    before(:each) do
      @none = ''
      @modified = "C lib/tddium.rb\n R spec/spec_helper.rb\n"
      @unknown = " ? spec/bogus_spec.rb\n"
      @tddium = Tddium.new
      stub_defaults
      stub_config_file(:api_key => true, :branches => true)
    end

    it "should signal no changes if there are none" do
      Open3.should_receive(:popen2e).once.and_return do |cmd, block|
        Open3SpecHelper.stubOpen2e(@none, true, block)
      end
      @tddium.send(:git_changes).should be_false
    end

    it "should ignore unknown files if there are any" do
      Open3.should_receive(:popen2e).once.and_return do |cmd, block|
        Open3SpecHelper.stubOpen2e(@unknown, true, block)
      end
      @tddium.send(:git_changes).should be_false
    end

    it "should signal uncommitted changes" do
      status = @unknown + @modified
      Open3.should_receive(:popen2e).once.and_return do |cmd, block|
        Open3SpecHelper.stubOpen2e(status, true, block)
      end
      @tddium.send(:git_changes).should be_true
    end
  end

  shared_examples_for "a password prompt" do
    context "--password was not passed in" do
      it "should prompt for a password or confirmation" do
        highline = mock(HighLine)
        HighLine.should_receive(:ask).with(password_prompt).and_yield(highline)
        highline.should_receive(:echo=).with("*")
        run(tddium)
      end
    end
    context "--password was passed in" do
      it "should not prompt for a password or confirmation" do
        HighLine.should_not_receive(:ask).with(password_prompt)
        run(tddium, :password => SAMPLE_PASSWORD)
      end
    end
  end

  shared_examples_for "an unsuccessful api call" do
    it "should show the error" do
      tddium_client.stub(:call_api).and_raise(TddiumClient::Error::Base)
      tddium.should_receive(:say).with(TddiumClient::Error::Base.new.message)
      run(tddium)
    end
  end

  shared_examples_for "git repo has not been initialized" do
    context "git repo has not been initialized" do
      before do
        FileUtils.rm_rf(".git")
        stub_git_status(tddium, false)
      end

      it "should return git is uninitialized" do
        tddium.should_receive(:say).with(Tddium::Text::Error::GIT_NOT_INITIALIZED)
        run(tddium)
      end
    end
  end

  shared_examples_for "getting the current suite from the API" do
    it "should send a 'GET' request to '#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}'" do
      call_api_should_receive(:method => :get, :path => "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}")
      run(tddium)
    end
  end

  shared_examples_for "sending the api key" do
    it "should call the api with the api key" do
      call_api_should_receive(:api_key => SAMPLE_API_KEY)
      run(tddium)
    end
  end

  shared_examples_for "set the default environment" do
    context "with environment parameter" do
      it "should should set the environment as the parameter of environment" do
        tddium_client.should_receive(:environment=).with(:test)
        run(tddium, :environment => "test")
      end
    end

    context "without environment parameter" do
      before do
        FileUtils.rm_rf(".tddium")
        FileUtils.rm_rf(".tddium.development")
        tddium_client.stub(:environment).and_return(:development)
      end

      it "should should set the environment as production if the file '.tddium.development' does not exist" do
        tddium_client.should_receive(:environment=).with(:production)
        run(tddium, :environment => nil)
      end

      it "should should set the environment as development if the file '.tddium.development' exists" do
        create_file(".tddium.development")
        tddium_client.should_receive(:environment=).with(:development)
        tddium_client.should_not_receive(:environment=).with(:production)
        run(tddium, :environment => nil)
      end
    end
  end

  shared_examples_for "suite has not been initialized" do
    context ".tddium file is missing" do
      before do
        stub_config_file(:api_key => true)
      end

      it "should tell the user '#{Tddium::Text::Error::NO_SUITE_EXISTS % SAMPLE_BRANCH_NAME}'" do
        tddium.should_receive(:say).with(Tddium::Text::Error::NO_SUITE_EXISTS % SAMPLE_BRANCH_NAME)
        run(tddium)
      end
    end
  end

  shared_examples_for ".tddium file is missing or corrupt" do
    context ".tddium file is missing" do
      before do
        FileUtils.rm_rf(SAMPLE_TDDIUM_CONFIG_FILE)
      end

      it "should tell the user '#{Tddium::Text::Error::NOT_INITIALIZED}'" do
        tddium.should_receive(:say).with(Tddium::Text::Error::NOT_INITIALIZED)
        run(tddium)
      end
    end

    context ".tddium file is corrupt" do
      before do
        create_file(SAMPLE_TDDIUM_CONFIG_FILE, "corrupt file")
      end

      it "should tell the user '#{Tddium::Text::Error::INVALID_TDDIUM_FILE % 'test'}'" do
        tddium.should_receive(:say).with(Tddium::Text::Error::INVALID_TDDIUM_FILE % 'test')
        run(tddium)
      end
    end
  end

  shared_examples_for "update the git remote and push" do
    context "git remote has changed" do
      before do
        stub_git_remote(tddium, :show, false)
        stub_git_remote(tddium, :add)
        stub_git_remote(tddium, :rm)
      end

      it "should remove all existing remotes called '#{Tddium::Git::REMOTE_NAME}'" do
        tddium.should_receive(:`).with("git remote rm #{Tddium::Git::REMOTE_NAME} > /dev/null 2>&1")
        run(tddium)
      end

      it "should add a new remote called '#{Tddium::Git::REMOTE_NAME}' to '#{SAMPLE_GIT_REPO_URI}'" do
        tddium.should_receive(:`).with("git remote add #{Tddium::Git::REMOTE_NAME} #{SAMPLE_GIT_REPO_URI}")
        run(tddium)
      end

    end

    context "git remote has not changed" do
      before do
        stub_git_remote(tddium)
      end

      it "should not remove any existing remotes" do
        tddium.should_not_receive(:`).with(/git remote rm/)
        run(tddium)
      end

      it "should not add any new remotes" do
        tddium.should_not_receive(:`).with(/git remote add/)
        run(tddium)
      end
    end

    it "should push the latest code to '#{Tddium::Git::REMOTE_NAME}'" do
      tddium.should_receive(:system).with("git push -f #{Tddium::Git::REMOTE_NAME} #{SAMPLE_BRANCH_NAME}")
      run(tddium)
    end
  end

  shared_examples_for "with the correct environment extension" do
    it "should write the api key to the .tddium file with the relevent environment extension" do
      run(tddium)
      tddium_file = File.open(".tddium#{environment_extension}") { |file| file.read }
      JSON.parse(tddium_file)["api_key"].should == SAMPLE_API_KEY
    end
  end

  shared_examples_for "writing the api key to the .tddium file" do
    context "production environment" do
      before { tddium_client.stub(:environment).and_return("production") }
      it_should_behave_like "with the correct environment extension" do
        let(:environment_extension) {""}
      end
    end

    context "development environment" do
      before { tddium_client.stub(:environment).and_return("development") }
      it_should_behave_like "with the correct environment extension" do
        let(:environment_extension) {".development"}
      end
    end

    context "test environment" do
      before { tddium_client.stub(:environment).and_return("test") }
      it_should_behave_like "with the correct environment extension" do
        let(:environment_extension) {".test"}
      end
    end
  end

  shared_examples_for "prompting for password" do
    it "should prompt for a password"  do
      highline = mock(HighLine)
      HighLine.should_receive(:ask).with(password_prompt).and_yield(highline)
      highline.should_receive(:echo=).with("*")
      run(tddium)
    end
  end

  describe "#password" do
    before do
      stub_defaults
      stub_config_file(:api_key => true, :branches => true)
      tddium.stub(:ask).and_return("")
      HighLine.stub(:ask).and_return("")
    end

    it_should_behave_like ".tddium file is missing or corrupt"

    context "the user is already logged in" do
      before do
        stub_call_api_response(:get, Tddium::Api::Path::USERS, SAMPLE_USER_RESPONSE)
      end

      it_should_behave_like "set the default environment"

      it_should_behave_like "prompting for password" do
        let(:password_prompt) {Tddium::Text::Prompt::CURRENT_PASSWORD}
      end

      it_should_behave_like "prompting for password" do
        let(:password_prompt) {Tddium::Text::Prompt::NEW_PASSWORD}
      end

      it_should_behave_like "prompting for password" do
        let(:password_prompt) {Tddium::Text::Prompt::PASSWORD_CONFIRMATION}
      end

      context "the user confirms their password correctly" do
        before do
          @user_path = "#{Tddium::Api::Path::USERS}/#{SAMPLE_USER_ID}/"
          HighLine.stub(:ask).with(Tddium::Text::Prompt::CURRENT_PASSWORD).and_return(SAMPLE_PASSWORD)
          HighLine.stub(:ask).with(Tddium::Text::Prompt::NEW_PASSWORD).and_return(SAMPLE_NEW_PASSWORD)
          HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD_CONFIRMATION).and_return(SAMPLE_NEW_PASSWORD)
        end


        it "should send a 'PUT' request to user_path with passwords" do
          call_api_should_receive(:method => :put,
                              :path => /#{@user_path}$/,
                              :params => {:user =>
                                 {:current_password=>SAMPLE_PASSWORD,
                                  :password => SAMPLE_NEW_PASSWORD,
                                  :password_confirmation => SAMPLE_NEW_PASSWORD}},
                              :api_key => SAMPLE_API_KEY)
          run_password(tddium)
        end

        context "'PUT user_path' is successful" do
          before{stub_call_api_response(:put, @user_path, {"status"=>0})}

          it "should show the user '#{Tddium::Text::Process::PASSWORD_CHANGED}'" do
            tddium.should_receive(:say).with(Tddium::Text::Process::PASSWORD_CHANGED)
            run_password(tddium)
          end
        end
        context "'PUT user_path' is unsuccessful" do

          context "invalid original password" do
            before{stub_call_api_response(:put, @user_path, PASSWORD_ERROR_RESPONSE)}
            it "should show the user: '#{Tddium::Text::Error::PASSWORD_ERROR}'" do
              tddium.should_receive(:say).with(Tddium::Text::Error::PASSWORD_ERROR % PASSWORD_ERROR_EXPLANATION)
              run_password(tddium)
            end
          end
        end
      end
    end
  end

  shared_examples_for "prompt for ssh key" do
    context "--ssh-key-file is not supplied" do
      it "should prompt the user for their ssh key file" do
        tddium.should_receive(:ask).with(Tddium::Text::Prompt::SSH_KEY % Tddium::Default::SSH_FILE, anything)
        run(tddium)
      end
    end

    context "--ssh-key-file is supplied" do
      it "should not prompt the user for their ssh key file" do
        tddium.should_not_receive(:ask).with(Tddium::Text::Prompt::SSH_KEY % Tddium::Default::SSH_FILE, anything)
        run(tddium, :ssh_key_file => Tddium::Default::SSH_FILE)
      end
    end
  end

  describe "#heroku" do
    before do
      stub_defaults
      tddium.stub(:ask).and_return("")
      HighLine.stub(:ask).and_return("")
      create_file(File.join(File.dirname(__FILE__), "..", Tddium::License::FILE_NAME), SAMPLE_LICENSE_TEXT)
      create_file(Tddium::Default::SSH_FILE, SAMPLE_SSH_PUBKEY)
      HerokuConfig.stub(:read_config).and_raise(HerokuConfig::HerokuNotFound)
    end

    context "the user is logged in to heroku, but not to tddium" do
      before do
        HerokuConfig.stub(:read_config).and_return(SAMPLE_HEROKU_CONFIG)
        @user_path = "#{Tddium::Api::Path::USERS}/#{SAMPLE_USER_ID}/"
      end

      context "the user has a properly configured add-on" do

        context "first-time account activation" do
          before do
            stub_call_api_response(:get, Tddium::Api::Path::USERS, SAMPLE_HEROKU_USER_RESPONSE)
            stub_call_api_response(:put, @user_path, {"status"=>0})
          end

          it_behaves_like "prompting for password" do
            let(:password_prompt) {Tddium::Text::Prompt::PASSWORD}
          end

          it_behaves_like "prompting for password" do
            let(:password_prompt) {Tddium::Text::Prompt::PASSWORD_CONFIRMATION}
          end

          it_behaves_like "prompt for ssh key"

          it "should display the heroku welcome" do
            tddium.should_receive(:say).with(Tddium::Text::Process::HEROKU_WELCOME % SAMPLE_EMAIL)
            run_heroku(tddium)
          end

          it "should send a 'PUT' request to user_path with passwords" do
            HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD).and_return(SAMPLE_PASSWORD)
            HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD_CONFIRMATION).and_return(SAMPLE_PASSWORD)
            call_api_should_receive(:method => :put,
                                :path => /#{@user_path}$/,
                                :params => {:user =>
                                   {:password => SAMPLE_PASSWORD,
                                    :password_confirmation => SAMPLE_PASSWORD,
                                    :user_git_pubkey => SAMPLE_SSH_PUBKEY},
                                   :heroku_activation => true},
                                :api_key => SAMPLE_API_KEY)
            heroku_should_fail(tddium) # call_api_should_receive stubs call_api with an error
          end

          context "PUT with passwords is successful" do
            before do
              stub_call_api_response(:put, @user_path, {"status"=>0})
            end

            it_should_behave_like "writing the api key to the .tddium file"

            it "should display the heroku configured welcome" do
              tddium.should_receive(:say).with(Tddium::Text::Status::HEROKU_CONFIG)
              run_heroku(tddium)
            end
          end

          context "PUT is unsuccessful" do
            before do
              stub_call_api_response(:put, @user_path, {"status" => 1, "explanation"=> "PUT error"})
            end

            it "should display an error message and fail" do
              heroku_should_fail(tddium) do
                tddium.should_receive(:exit_failure).with(Tddium::Text::Error::HEROKU_MISCONFIGURED % "200 OK (1) PUT error")
              end
            end
          end
        end

        context "re-run after account is activated" do
          before do 
            stub_call_api_response(:get, Tddium::Api::Path::USERS, SAMPLE_USER_RESPONSE)
          end

          it "should display the heroku configured welcome" do
            tddium.should_receive(:say).with(Tddium::Text::Status::HEROKU_CONFIG)
            run_heroku(tddium)
          end

          it_should_behave_like "writing the api key to the .tddium file"
        end
      end

      context "the heroku config contains an unrecognized API key" do
        let(:call_api_result) {[403, "Forbidden"]}

        it "should display an error message and fail" do
          heroku_should_fail(tddium) do
            tddium.should_receive(:exit_failure).with(Tddium::Text::Error::HEROKU_MISCONFIGURED % "Unrecognized user")
          end
        end
      end
    end
  end


  describe "#account" do
    before do
      stub_defaults
      tddium.stub(:ask).and_return("")
      HighLine.stub(:ask).and_return("")
      create_file(File.join(File.dirname(__FILE__), "..", Tddium::License::FILE_NAME), SAMPLE_LICENSE_TEXT)
      create_file(Tddium::Default::SSH_FILE, SAMPLE_SSH_PUBKEY)
      HerokuConfig.stub(:read_config).and_return(nil)
    end

    it_should_behave_like "set the default environment"

    context "the user is already logged in" do
      before do
        stub_config_file(:api_key => SAMPLE_API_KEY)
        stub_call_api_response(:get, Tddium::Api::Path::USERS, SAMPLE_USER_RESPONSE)
      end

      it "should show the user's email address" do
        tddium.should_receive(:say).with(/#{SAMPLE_EMAIL}/)
        run_account(tddium)
      end

      it "should show the user's account creation date" do
        tddium.should_receive(:say).with(/#{SAMPLE_DATE_TIME}/)
        run_account(tddium)
      end

      it "should show the user's recurly account url" do
        tddium.should_receive(:say).with(/#{SAMPLE_RECURLY_URL}/)
        run_account(tddium)
      end

    end

    context "the user is not already logged in" do
      let(:call_api_result) {[403, "Forbidden"]}

      it_should_behave_like "a password prompt" do
        let(:password_prompt) {Tddium::Text::Prompt::PASSWORD_CONFIRMATION}
      end

      context "the user does not confirm their password correctly" do
        before {HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD_CONFIRMATION).and_return("wrong confirmation")}
        it "should tell the user '#{Tddium::Text::Process::PASSWORD_CONFIRMATION_INCORRECT}'" do
          tddium.should_receive(:say).with(Tddium::Text::Process::PASSWORD_CONFIRMATION_INCORRECT)
          run_account(tddium)
        end
      end

      context "the user confirms their password correctly" do
        before do
          HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD).and_return(SAMPLE_PASSWORD)
          HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD_CONFIRMATION).and_return(SAMPLE_PASSWORD)
        end

        it_behaves_like "prompt for ssh key"

        it "should show the user the license" do
          tddium.should_receive(:say).with(SAMPLE_LICENSE_TEXT)
          run_account(tddium)
        end

        it "should ask the user to accept the license" do
          tddium.should_receive(:ask).with(Tddium::Text::Prompt::LICENSE_AGREEMENT)
          run_account(tddium)
        end

        context "accepting the license" do
          before do
            tddium.stub(:ask).with(Tddium::Text::Prompt::LICENSE_AGREEMENT).and_return(Tddium::Text::Prompt::Response::AGREE_TO_LICENSE)
            tddium.stub(:ask).with(Tddium::Text::Prompt::INVITATION_TOKEN).and_return(SAMPLE_INVITATION_TOKEN)
            create_file(Tddium::Default::SSH_FILE, "ssh-rsa 1234")
          end

          it "should send a 'POST' request to '#{Tddium::Api::Path::USERS}' with the user's invitation token, password and ssh key" do
            call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::USERS}$/, :params => {:user => {:invitation_token => SAMPLE_INVITATION_TOKEN, :password => SAMPLE_PASSWORD, :user_git_pubkey => "ssh-rsa 1234"}}, :api_key => false)
            run_account(tddium)
          end

          context "'POST #{Tddium::Api::Path::USERS}' is successful" do
            before{stub_call_api_response(:post, Tddium::Api::Path::USERS, SAMPLE_USER_RESPONSE)}

            it_should_behave_like "writing the api key to the .tddium file"

            it "should show the user '#{Tddium::Text::Process::ACCOUNT_CREATED % [SAMPLE_EMAIL, SAMPLE_RECURLY_URL]}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::ACCOUNT_CREATED % [SAMPLE_EMAIL, SAMPLE_RECURLY_URL])
              run_account(tddium)
            end
          end
          context "'POST #{Tddium::Api::Path::USERS}' is unsuccessful" do

            it_should_behave_like "an unsuccessful api call"

            context "because the invitation is invalid" do
              before { stub_call_api_response(:post, Tddium::Api::Path::USERS, {"status" => Tddium::Api::ErrorCode::INVALID_INVITATION}) }
              it "should show the user: '#{Tddium::Text::Error::INVALID_INVITATION}'" do
                tddium.should_receive(:say).with(Tddium::Text::Error::INVALID_INVITATION)
                run_account(tddium)
              end
            end
          end
        end
      end
    end
  end

  describe "#login" do
    before do
      stub_defaults
      tddium.stub(:ask).and_return("")
      HighLine.stub(:ask).and_return("")
    end

    it_should_behave_like "set the default environment"

    context "there is a tddium config file with an api key" do
      before {stub_config_file(:api_key => "some api key")}

      it "should send a 'GET' request to '#{Tddium::Api::Path::USERS}'" do
        call_api_should_receive(:method => :get, :path => /#{Tddium::Api::Path::USERS}$/)
        run(tddium)
      end
    end

    context "the tddium config file is missing or corrupt or the api key is invalid" do
      context "--email was not passed in" do
        it "should prompt for the user's email address" do
          tddium.should_receive(:ask).with(Tddium::Text::Prompt::EMAIL)
          run(tddium)
        end
      end

      context "--email was passed in" do
        it "should not prompt for the user's email address" do
          tddium.should_not_receive(:ask).with(Tddium::Text::Prompt::EMAIL)
          run(tddium, :email => SAMPLE_EMAIL)
        end
      end

      it_should_behave_like "a password prompt" do
        let(:password_prompt) {Tddium::Text::Prompt::PASSWORD}
      end

      it "should try to sign in the user with their email & password" do
        tddium.stub(:ask).with(Tddium::Text::Prompt::EMAIL).and_return(SAMPLE_EMAIL)
        HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD).and_return(SAMPLE_PASSWORD)
        call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::SIGN_IN}$/, :params => {:user => {:email => SAMPLE_EMAIL, :password => SAMPLE_PASSWORD}}, :api_key => false)
        run(tddium)
      end

      context "the user logs in successfully with their email and password" do
        before{stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, {"api_key" => SAMPLE_API_KEY})}
        it_should_behave_like "writing the api key to the .tddium file"
      end
    end

    context "user is already logged in" do
      before do
        stub_config_file(:api_key => SAMPLE_API_KEY)
        stub_call_api_response(:get, Tddium::Api::Path::USERS)
      end

      it "should show the user: '#{Tddium::Text::Process::ALREADY_LOGGED_IN}'" do
        tddium.should_receive(:say).with(Tddium::Text::Process::ALREADY_LOGGED_IN)
        run_login(tddium)
      end
    end

    context "the user logs in successfully" do
      before{ stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, {"api_key" => SAMPLE_API_KEY})}
      it "should show the user: '#{Tddium::Text::Process::LOGGED_IN_SUCCESSFULLY}'" do
        tddium.should_receive(:say).with(Tddium::Text::Process::LOGGED_IN_SUCCESSFULLY)
        run_login(tddium)
      end
    end

    context "the user does not sign in successfully" do
      it_should_behave_like "an unsuccessful api call"
    end
  end

  describe "#logout" do
    before { stub_defaults }

    context ".tddium file exists" do
      before { stub_config_file }
      it "should delete the file" do
        run_logout(tddium)
        File.should_not be_exists(SAMPLE_TDDIUM_CONFIG_FILE)
      end
    end

    context ".tddium file does not exists" do
      it "should do nothing" do
        FileUtils.should_not_receive(:rm)
        run_logout(tddium)
      end
    end

    it "should show the user: '#{Tddium::Text::Process::LOGGED_OUT_SUCCESSFULLY}'" do
      tddium.should_receive(:say).with(Tddium::Text::Process::LOGGED_OUT_SUCCESSFULLY)
      run_logout(tddium)
    end
  end

  describe "#spec" do
    before do
      stub_defaults
      stub_config_file(:api_key => true, :branches => true)
    end

    it_should_behave_like "set the default environment" do
      let(:run_function) {spec_should_fail}
    end
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium file is missing or corrupt"
    it_should_behave_like "suite has not been initialized"

    context "user-data-file" do
      context "does not exist" do
        context "from command line option" do
          it "should be picked first" do
            spec_should_fail(tddium, :user_data_file => SAMPLE_FILE_PATH) do
              tddium.should_receive(:exit_failure).with(Tddium::Text::Error::NO_USER_DATA_FILE % SAMPLE_FILE_PATH)
            end
          end
        end

        context "from the previous option" do
          before { stub_config_file(:branches => {SAMPLE_BRANCH_NAME => {"id" => SAMPLE_SUITE_ID, "options" => {"user_data_file" => SAMPLE_FILE_PATH2}}}) }

          it "should be picked if no command line option" do
            spec_should_fail(tddium) do
              tddium.should_receive(:exit_failure).with(Tddium::Text::Error::NO_USER_DATA_FILE % SAMPLE_FILE_PATH2)
            end
          end
        end

        it "should not try to git push" do
          tddium.should_not_receive(:system).with(/^git push/)
          spec_should_fail(tddium, :user_data_file => SAMPLE_FILE_PATH)
        end

        it "should not call the api" do
          tddium_client.should_not_receive(:call_api)
          spec_should_fail(tddium, :user_data_file => SAMPLE_FILE_PATH)
        end
      end
    end

    it_should_behave_like "getting the current suite from the API"
    it_should_behave_like "sending the api key"

    context "'GET #{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}' is successful" do
      before do
        stub_call_api_response(:get, "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}", {"suite"=>SAMPLE_SUITE_RESPONSE})
        stub_git_push(tddium)
        stub_git_remote(tddium)
        create_file("spec/mouse_spec.rb")
        create_file("spec/cat_spec.rb")
        create_file("spec/dog_spec.rb")
      end

      it_should_behave_like "update the git remote and push"

      context "git push was unsuccessful" do
        before { stub_git_push(tddium, false) }
        it "should not try to create a new session" do
          tddium.should_receive(:exit_failure)
          tddium_client.should_not_receive(:call_api).with(:post, Tddium::Api::Path::SESSIONS)
          run_spec(tddium)
        end
      end

      it "should send a 'POST' request to '#{Tddium::Api::Path::SESSIONS}'" do
        call_api_should_receive(:method => :post, :path => Tddium::Api::Path::SESSIONS)
        run_spec(tddium)
      end

      it_should_behave_like "sending the api key"

      it "should fail on an API error" do
        stub_call_api_error(:post, Tddium::Api::Path::SESSIONS, 403, "Access Denied")
        spec_should_fail(tddium)
      end

      it "should fail on any other error" do
        tddium_client.stub(:call_api).with(anything, anything, anything, anything).and_raise("generic runtime error")
        spec_should_fail(tddium)
      end

      context "'POST #{Tddium::Api::Path::SESSIONS}' is successful" do
        before do
          response = {"session"=>{"id"=>SAMPLE_SESSION_ID}}
          stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}", response)
        end

        it "should send a 'POST' request to '#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}'" do
          call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}$/)
          run_spec(tddium)
        end

        it_should_behave_like "sending the api key"

        context "test pattern" do
          context "default test pattern" do
            it "should POST the test_pattern parameter" do
              current_dir = Dir.pwd
              call_api_should_receive(:params => {:suite_id => SAMPLE_SUITE_ID,
                                                  :test_pattern => nil})
              run_spec(tddium)
            end
          end

          context "--test-pattern=#{CUSTOM_TEST_PATTERN}" do
            it "should post the test_pattern extracted from the test_pattern parameter" do
              current_dir = Dir.pwd
              call_api_should_receive(:params => {:suite_id => SAMPLE_SUITE_ID,
                                      :test_pattern => CUSTOM_TEST_PATTERN})
              run_spec(tddium, {:test_pattern=>CUSTOM_TEST_PATTERN})
            end
          end

          context "remembered from last run" do
            it "should POST the remembered test_pattern" do
              tddium.stub(:current_suite_options).and_return({'test_pattern'=>CUSTOM_TEST_PATTERN})
              current_dir = Dir.pwd
              call_api_should_receive(:params => {:suite_id => SAMPLE_SUITE_ID,
                                      :test_pattern => CUSTOM_TEST_PATTERN})
              run_spec(tddium)
            end
          end
        end

        context "'POST #{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}' is successful" do
          before do
            response = {"added"=>0, "existing"=>1, "errors"=>0, "status"=>0}
            stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}", response)
          end

          it "should send a 'POST' request to '#{Tddium::Api::Path::START_TEST_EXECUTIONS}'" do
            call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/)
            run_spec(tddium)
          end

          context "--user-data-file=#{SAMPLE_FILE_PATH}" do
            before { create_file(SAMPLE_FILE_PATH, SAMPLE_PASSWORD) }
            it "should send 'user_data_filename=#{File.basename(SAMPLE_FILE_PATH)}' to '#{Tddium::Api::Path::START_TEST_EXECUTIONS}'" do
              call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/, :params => hash_including(:user_data_filename => File.basename(SAMPLE_FILE_PATH)))
              run_spec(tddium, :user_data_file => SAMPLE_FILE_PATH)
            end

            it "should send 'user_data-text=#{Base64.encode64(SAMPLE_PASSWORD)}' (Base64 encoded file content)" do
              call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/, :params => hash_including(:user_data_text => Base64.encode64(SAMPLE_PASSWORD)))
              run_spec(tddium, :user_data_file => SAMPLE_FILE_PATH)
            end
          end

          context "max_parallelism" do
            context "from command line option" do
              it "should be picked first" do
                call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/, :params => hash_including(:max_parallelism => 5))
                run_spec(tddium, :max_parallelism => 5)
              end
            end

            context "from the previous option" do
              before { stub_config_file(:branches => {SAMPLE_BRANCH_NAME => {"id" => SAMPLE_SUITE_ID, "options" => {"max_parallelism" => 10}}}) }

              it "should be picked if no command line option" do
                call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/, :params => hash_including(:max_parallelism => 10))
                run_spec(tddium)
              end
            end
          end

          it_should_behave_like "sending the api key"

          context "'POST #{Tddium::Api::Path::START_TEST_EXECUTIONS}' is successful" do
            let(:get_test_executions_response) { {"report"=>SAMPLE_REPORT_URL, "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"pending"}, "spec/pig_spec.rb"=>{"finished" => false, "status"=>"started"}, "spec/dog_spec.rb"=>{"finished" => true, "status"=>"failed"}, "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}} }
            before {stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::START_TEST_EXECUTIONS}", {"started"=>1, "status"=>0, "report" => SAMPLE_REPORT_URL})}

            it "should show the user: '#{Tddium::Text::Process::CHECK_TEST_REPORT % SAMPLE_REPORT_URL}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::CHECK_TEST_REPORT % SAMPLE_REPORT_URL)
              run_spec(tddium)
            end

            it "should tell the user to '#{Tddium::Text::Process::TERMINATE_INSTRUCTION}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::TERMINATE_INSTRUCTION)
              run_spec(tddium)
            end

            it "should tell the user '#{Tddium::Text::Process::STARTING_TEST % 1}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::STARTING_TEST % 1)
              run_spec(tddium)
            end

            it "should send a 'GET' request to '#{Tddium::Api::Path::TEST_EXECUTIONS}'" do
              call_api_should_receive(:method => :get, :path => /#{Tddium::Api::Path::TEST_EXECUTIONS}$/)
              run_spec(tddium)
            end

            it_should_behave_like "sending the api key"

            shared_examples_for("test output summary") do
              it "should put a new line before displaying the summary" do
                tddium.should_receive(:say).with("")
                run_spec(tddium)
              end

              it "should show the user the time taken" do
                tddium.should_receive(:say).with(/^#{Tddium::Text::Process::FINISHED_TEST % "[\\d\\.]+"}$/)
                run_spec(tddium)
              end
            end

            context "user presses 'Ctrl-C' during the process" do
              before do
                stub_call_api_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::TEST_EXECUTIONS}", get_test_executions_response)
                Signal.stub(:trap).with(:INT).and_yield
                stub_sleep(tddium)
              end

              it "should show the user '#{Tddium::Text::Process::INTERRUPT}'" do
                tddium.should_receive(:say).with(Tddium::Text::Process::INTERRUPT)
                run_spec(tddium)
              end

              it "should show the user '#{Tddium::Text::Process::CHECK_TEST_STATUS}'" do
                tddium.should_receive(:say).with(Tddium::Text::Process::CHECK_TEST_STATUS)
                run_spec(tddium)
              end

              it "should show the user a summary of all the tests" do
                tddium.should_receive(:say).with("3 tests, 1 failures, 0 errors, 1 pending")
                run_spec(tddium)
              end

              it_should_behave_like("test output summary")
            end

            context "'GET #{Tddium::Api::Path::TEST_EXECUTIONS}' is successful" do
              context "with mixed results" do
                before do
                  get_test_executions_response_all_finished = {"report"=>SAMPLE_REPORT_URL, "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"pending"}, "spec/pig_spec.rb"=>{"finished" => true, "status"=>"error"}, "spec/dog_spec.rb"=>{"finished" => true, "status"=>"failed"}, "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}
                  stub_call_api_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::TEST_EXECUTIONS}", get_test_executions_response, get_test_executions_response_all_finished)
                  stub_sleep(tddium)
                end

                it "should sleep for #{Tddium::Default::SLEEP_TIME_BETWEEN_POLLS} seconds" do
                  tddium.should_receive(:sleep).exactly(1).times.with(Tddium::Default::SLEEP_TIME_BETWEEN_POLLS)
                  run_spec(tddium)
                end

                it "should display a green '.'" do
                  tddium.should_receive(:say).with(".", :green, false)
                  run_spec(tddium)
                end

                it "should display a red 'F'" do
                  tddium.should_receive(:say).with("F", :red, false)
                  run_spec(tddium)
                end

                it "should display a yellow '*'" do
                  tddium.should_receive(:say).with("*", :yellow, false)
                  run_spec(tddium)
                end

                it "should display 'E' with no color" do
                  tddium.should_receive(:say).with("E", nil, false)
                  run_spec(tddium)
                end

                it "should display a summary of all the tests" do
                  tddium.should_receive(:say).with("4 tests, 1 failures, 1 errors, 1 pending")
                  spec_should_fail(tddium) do
                    tddium.should_receive(:exit_failure).once
                  end
                end

                it "should save the spec options" do
                  tddium.should_receive(:write_suite).with(SAMPLE_SUITE_RESPONSE, {"user_data_file" => nil, "max_parallelism" => 3, "test_pattern" => nil})
                  run_spec(tddium, {:max_parallelism => 3})
                end

                it_should_behave_like("test output summary")
              end

              context "with only errors" do
                before do
                  get_test_executions_response_errors = {"report"=>SAMPLE_REPORT_URL, "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"error"}, "spec/pig_spec.rb"=>{"finished" => true, "status"=>"error"}, "spec/dog_spec.rb"=>{"finished" => true, "status"=>"error"}, "spec/cat_spec.rb"=>{"finished" => true, "status"=>"error"}}}
                  stub_call_api_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::TEST_EXECUTIONS}", get_test_executions_response_errors)
                  stub_sleep(tddium)
                end
                it "should display a summary of all the tests and exit failure" do
                  tddium.should_receive(:say).with("4 tests, 0 failures, 4 errors, 0 pending")
                  spec_should_fail(tddium) do
                    tddium.should_receive(:exit_failure).once
                  end
                end
              end

              context "with no errors" do
                before do
                  get_test_executions_response_all_passed = {
                    "report"=>SAMPLE_REPORT_URL, 
                    "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"passed"},
                              "spec/pig_spec.rb"=>{"finished" => true, "status"=>"passed"},
                              "spec/dog_spec.rb"=>{"finished" => true, "status"=>"passed"},
                              "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}
                  stub_call_api_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::TEST_EXECUTIONS}", get_test_executions_response_all_passed)
                  stub_sleep(tddium)
                end

                it "should display a green '.'" do
                  tddium.should_receive(:say).with(".", :green, false)
                  run_spec(tddium)
                end

                it "should not display a red 'F'" do
                  tddium.should_not_receive(:say).with("F", :red, false)
                  run_spec(tddium)
                end

                it "should not display a yellow '*'" do
                  tddium.should_not_receive(:say).with("*", :yellow, false)
                  run_spec(tddium)
                end

                it "should not display 'E' with no color" do
                  tddium.should_not_receive(:say).with("E", nil, false)
                  run_spec(tddium)
                end

                it "should display a summary of all the tests" do
                  tddium.should_receive(:say).with("4 tests, 0 failures, 0 errors, 0 pending")
                  spec_should_pass(tddium) do
                    tddium.should_not_receive(:exit_failure)
                  end
                end

                it "should save the spec options" do
                  tddium.should_receive(:write_suite).with(SAMPLE_SUITE_RESPONSE, {"user_data_file" => nil, "max_parallelism" => 3, "test_pattern" => nil})
                  run_spec(tddium, {:max_parallelism => 3})
                end

                it_should_behave_like("test output summary")
              end
            end

            it_should_behave_like "an unsuccessful api call"
          end

          it_should_behave_like "an unsuccessful api call"
        end

        it_should_behave_like "an unsuccessful api call"
      end

      it_should_behave_like "an unsuccessful api call"
    end

    it_should_behave_like "an unsuccessful api call"
  end

  describe "#status" do
    before do
      stub_defaults
      stub_config_file(:api_key => true, :branches => true)
    end

    it_should_behave_like "set the default environment"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium file is missing or corrupt"
    it_should_behave_like "suite has not been initialized"

    it "should send a 'GET' request to '#{Tddium::Api::Path::SUITES}'" do
      call_api_should_receive(:method => :get, :path => Tddium::Api::Path::SUITES)
      run_status(tddium)
    end

    context "'GET #{Tddium::Api::Path::SUITES}' is successful" do
      context "but returns no suites" do
        before { stub_call_api_response(:get, Tddium::Api::Path::SUITES, {"suites" => []}) }

        it "should show the user '#{Tddium::Text::Status::NO_SUITE}'" do
          tddium.should_receive(:say).with(Tddium::Text::Status::NO_SUITE)
          run_status(tddium)
        end
      end

      context "and returns some suites" do
        let(:suite_attributes) { {"id"=>SAMPLE_SUITE_ID, "repo_name"=>SAMPLE_APP_NAME, "ruby_version"=>SAMPLE_RUBY_VERSION, "branch" => SAMPLE_BRANCH_NAME, "bundler_version" => SAMPLE_BUNDLER_VERSION, "rubygems_version" => SAMPLE_RUBYGEMS_VERSION}}
        before do
          stub_call_api_response(:get, Tddium::Api::Path::SUITES, {"suites"=>[suite_attributes]})
        end

        it "should show all suites" do
          tddium.should_receive(:say).with(Tddium::Text::Status::ALL_SUITES % SAMPLE_APP_NAME)
          run_status(tddium)
        end

        context "without current suite" do
          before { stub_config_file(:branches => {SAMPLE_BRANCH_NAME => {"id" => 0}}) }
          it "should show the user '#{Tddium::Text::Status::CURRENT_SUITE_UNAVAILABLE}'" do
            tddium.should_receive(:say).with(Tddium::Text::Status::CURRENT_SUITE_UNAVAILABLE)
            run_status(tddium)
          end
        end

        context "with current suite" do
          shared_examples_for "attribute details" do
            it "should show the user the attribute details" do
              attributes_to_display.each do |attr|
                if attributes[attr]
                  tddium.should_receive(:say).with(Tddium::Text::Status::ATTRIBUTE_DETAIL % [attr.gsub("_", " ").capitalize, attributes[attr]])
                else
                  tddium.should_not_receive(:say).with(/#{attr.gsub("_", " ").capitalize}/)
                end
              end
              run_status(tddium)
            end

            it "should not show the user irrelevent attributes" do
              attributes_to_hide.each do |regexp|
                tddium.should_not_receive(:say).with(regexp)
              end
              run_status(tddium)
            end
          end

          it "should show the separator" do
            tddium.should_receive(:say).with(Tddium::Text::Status::SEPARATOR)
            run_status(tddium)
          end

          it "should show user the current suite name" do
            tddium.should_receive(:say).with(Tddium::Text::Status::CURRENT_SUITE % SAMPLE_APP_NAME)
            run_status(tddium)
          end

          it_should_behave_like "attribute details" do
            let(:attributes_to_display) {Tddium::DisplayedAttributes::SUITE}
            let(:attributes_to_hide) { [/id/] }
            let(:attributes) { suite_attributes }
          end

          context "show active sessions" do
            context "without any session" do
              before do
                stub_call_api_response(:get, Tddium::Api::Path::SESSIONS, {"sessions"=>[]})
              end

              it "should display no active session message" do
                tddium.should_receive(:say).with(Tddium::Text::Status::NO_ACTIVE_SESSION)
                run_status(tddium)
              end
            end

            context "with some sessions" do
              let(:session_attributes) do
                {"id" => SAMPLE_SESSION_ID, "user_id" => 3,
                 "report" => SAMPLE_REPORT_URL, "test_execution_stats" => SAMPLE_TEST_EXECUTION_STATS,
                 "start_time" => SAMPLE_DATE_TIME, "end_time" => SAMPLE_DATE_TIME}
              end

              before do
                stub_call_api_response(:get, Tddium::Api::Path::SESSIONS, {"sessions"=>[session_attributes]})
              end

              it "should show the user: '#{Tddium::Text::Status::ACTIVE_SESSIONS}'" do
                tddium.should_receive(:say).with(Tddium::Text::Status::ACTIVE_SESSIONS)
                run_status(tddium)
              end

              it_should_behave_like "attribute details" do
                let(:attributes_to_display) {Tddium::DisplayedAttributes::TEST_EXECUTION}
                let(:attributes_to_hide) { [] }
                let(:attributes) { session_attributes }
              end
            end
          end
        end

        it "should send a 'GET' request to '#{Tddium::Api::Path::ACCOUNT_USAGE}'" do
          call_api_should_receive(:method => :get, :path => Tddium::Api::Path::ACCOUNT_USAGE)
          run_status(tddium)
        end

        context "'GET #{Tddium::Api::Path::SUITES}' is successful" do
          before { stub_call_api_response(:get, Tddium::Api::Path::ACCOUNT_USAGE, {"usage" => "something"}) }

          it "should display the account usage" do
            tddium.should_receive(:say).with("something")
            run_status(tddium)
          end
        end
      end
    end

    it_should_behave_like "an unsuccessful api call"
  end

  describe "#suite" do
    before do
      stub_defaults
      stub_config_file(:api_key => true)
      stub_ruby_version(tddium)
      stub_rubygems_version(tddium)
      stub_bundler_version(tddium)
      tddium.stub(:ask).and_return("")
    end

    shared_examples_for "prompting for suite configuration" do
      it "should prompt for URLs" do
        tddium.should_receive(:ask).with(Tddium::Text::Prompt::CI_PULL_URL % current.fetch('ci_pull_url', SAMPLE_GIT_REPO_URI), anything)
        tddium.should_receive(:ask).with(Tddium::Text::Prompt::CI_PUSH_URL % current['ci_push_url'], anything)
        run_suite(tddium)
      end

      it "should prompt for campfire" do
        tddium.should_receive(:ask).with(Tddium::Text::Prompt::CAMPFIRE_SUBDOMAIN % current['campfire_subdomain'], anything)
        tddium.should_receive(:ask).with(Tddium::Text::Prompt::CAMPFIRE_TOKEN % current['campfire_token'], anything)
        tddium.should_receive(:ask).with(Tddium::Text::Prompt::CAMPFIRE_ROOM % current['campfire_room'], anything)
        run_suite(tddium)
      end
    end

    it_should_behave_like "set the default environment"
    it_should_behave_like "sending the api key"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium file is missing or corrupt"

    context ".tddium file contains no suites" do
      before do
        stub_default_suite_name
        stub_call_api_response(:get, Tddium::Api::Path::SUITES, {"suites" => []})
      end

      context "using defaults" do
        it "should send a 'GET' request to '#{Tddium::Api::Path::SUITES} with the repo name and branch name'" do
          call_api_should_receive(:method => :get, :path => Tddium::Api::Path::SUITES, :params => hash_including(:repo_name => SAMPLE_APP_NAME, :branch => SAMPLE_BRANCH_NAME))
          run_suite(tddium)
        end
      end

      context "passing '--name=my_suite'" do
        let(:cli_args) { { :name => "my_suite" } }

        it "should not ask for a suite name" do
          tddium.should_not_receive(:ask).with(Tddium::Text::Prompt::SUITE_NAME % SAMPLE_APP_NAME)
          run_suite(tddium, cli_args)
        end

        it "should send a GET request with the passed in values to the API" do
          call_api_should_receive(:method => :get, :path => Tddium::Api::Path::SUITES, :params => hash_including(:repo_name => "my_suite"))
          run_suite(tddium, cli_args)
        end
      end

      context "interactive mode" do
        before { tddium.stub(:ask).with(Tddium::Text::Prompt::SUITE_NAME % SAMPLE_APP_NAME, anything).and_return("some_other_suite") }

        it "should ask for a suite name" do
          tddium.should_receive(:ask).with(Tddium::Text::Prompt::SUITE_NAME % SAMPLE_APP_NAME, anything)
          run_suite(tddium)
        end

        it "should send a GET request with the user's entries to the API" do
          call_api_should_receive(:method => :get, :path => Tddium::Api::Path::SUITES, :params => hash_including(:repo_name => "some_other_suite"))
          run_suite(tddium)
        end
      end

      context "passing '--name=my_suite'" do
        it "should POST request with the passed in values to the API" do
          call_api_should_receive(:method => :post, :path => Tddium::Api::Path::SUITES, :params => {:suite => hash_including(:repo_name => "my_suite")})
          run_suite(tddium, :name => "my_suite")
        end
      end

      context "but this user has already registered some suites" do
        before do
          stub_call_api_response(:get, Tddium::Api::Path::SUITES, SAMPLE_SUITES_RESPONSE, {"suites" => []})
          tddium.stub(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_BRANCH_NAME % SAMPLE_APP_NAME, anything).and_return(Tddium::Text::Prompt::Response::YES)
        end

        shared_examples_for "writing the suite to file" do
          it "should write the suite id and branch name to the .tddium file" do
            run_suite(tddium)
            tddium_file = File.open(SAMPLE_TDDIUM_CONFIG_FILE) { |file| file.read }
            JSON.parse(tddium_file)["branches"][SAMPLE_BRANCH_NAME]["id"].should == SAMPLE_SUITE_ID
          end

          it "should update the gitignore file with tddium" do
            run_suite(tddium)
            gitignore_file = File.open(Tddium::Git::GITIGNORE) { |file| file.read }
            gitignore_file.should include(".tddium.test")
            gitignore_file.should include("something")
          end

          it "it should create .gitignore with tddium if it doesn't exist" do
            FileUtils.rm_f(Tddium::Git::GITIGNORE)
            run_suite(tddium)
            gitignore_file = File.open(Tddium::Git::GITIGNORE) { |file| file.read }
            gitignore_file.should include(".tddium.test")
          end
        end

        context "passing no cli options" do
          it "should ask the user: '#{Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_BRANCH_NAME % SAMPLE_APP_NAME}' " do
            tddium.should_receive(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_BRANCH_NAME % SAMPLE_APP_NAME, anything).and_return("something")
            run_suite(tddium)
          end
        end

        context "passing --name=my_suite" do
          before do
            stub_call_api_response(:get, Tddium::Api::Path::SUITES, SAMPLE_SUITES_RESPONSE)
          end

          it "should not ask the user if they want to use the existing suite" do
            tddium_client.should_not_receive(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % "my_suite", anything)
            run_suite(tddium, :name => "my_suite")
          end

          it "should not POST the passed in values to the API" do
            tddium_client.should_not_receive(:call_api).with(:post)
            run_suite(tddium, :name => "my_suite")
          end

          it_should_behave_like "writing the suite to file"

        end

        context "the user wants to use the existing suite" do
          before do
            stub_call_api_response(:get, Tddium::Api::Path::SUITES, SAMPLE_SUITES_RESPONSE)
          end

          it "should not send a 'POST' request to '#{Tddium::Api::Path::SUITES}'" do
            tddium_client.should_not_receive(:call_api).with(:method => :post, :path => Tddium::Api::Path::SUITES)
            run_suite(tddium)
          end

          it_should_behave_like "writing the suite to file"

          it "should show the user: sample suite output" do
            tddium.should_receive(:say).with(Tddium::Text::Status::USING_SUITE % tddium.send(:format_suite_details, SAMPLE_SUITE_RESPONSE))
            run_suite(tddium)
          end
        end

        context "the user does not want to use the existing suite" do
          before{ tddium.stub(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_BRANCH_NAME % SAMPLE_APP_NAME, anything).and_return("some_other_suite") }


          it "should send a 'POST' request to '#{Tddium::Api::Path::SUITES}'" do
            call_api_should_receive(:method => :post, :path => Tddium::Api::Path::SUITES)
            run_suite(tddium)
          end

          it "should post the user's current ruby version to the API" do
            stub_ruby_version(tddium)
            call_api_should_receive(:params => {:suite => hash_including(:ruby_version => SAMPLE_RUBY_VERSION)})
            run_suite(tddium)
          end

          it "should post the user's current branch to the API" do
            stub_ruby_version(tddium)
            call_api_should_receive(:params => {:suite => hash_including(:branch => SAMPLE_BRANCH_NAME)})
            run_suite(tddium)
          end

          it "should post the user's bundler version to the API" do
            stub_ruby_version(tddium)
            call_api_should_receive(:params => {:suite => hash_including(:bundler_version => SAMPLE_BUNDLER_VERSION)})
            run_suite(tddium)
          end

          it "should post the user's rubygems version to the API" do
            stub_ruby_version(tddium)
            call_api_should_receive(:params => {:suite => hash_including(:rubygems_version => SAMPLE_RUBYGEMS_VERSION)})
            run_suite(tddium)
          end

          context "interactive mode" do
            before do
              tddium.stub(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_BRANCH_NAME % SAMPLE_APP_NAME, anything).and_return("foobar")
              tddium.stub(:ask).with(Tddium::Text::Prompt::TEST_PATTERN % Tddium::Default::SUITE_TEST_PATTERN, anything).and_return(SAMPLE_SUITE_PATTERN)
              stub_default_suite_name
            end

            context "no ci url" do
              it "should POST the user's entered values to the API" do
                tddium.should_receive(:say).with(Tddium::Text::Process::CREATING_SUITE % ["foobar", SAMPLE_BRANCH_NAME])
                call_api_should_receive(:method => :post, :params => {:suite => hash_including(:repo_name => "foobar", :test_pattern=>SAMPLE_SUITE_PATTERN)})
                run_suite(tddium)
              end
            end

            it_behaves_like "prompting for suite configuration" do
              let(:current) { {} }
            end
          end

          context "API response successful" do
            before do
              stub_call_api_response(:post, Tddium::Api::Path::SUITES, {"suite"=>SAMPLE_SUITE_RESPONSE})
              stub_git_remote(tddium)
              stub_git_push(tddium)
            end

            it_should_behave_like("writing the suite to file")
            it_should_behave_like("update the git remote and push")
          end
          it_should_behave_like "an unsuccessful api call"
        end
      end
    end

    context "suite has already been registered" do
      before do
        stub_config_file(:api_key => true, :branches => true)
      end

      context "'GET #{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}' is successful" do
        before(:each) do
          stub_call_api_response(:get, "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}", {"suite"=>SAMPLE_SUITE_RESPONSE})
          stub_call_api_response(:put, "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}", {"status"=>0})
        end

        it "should not ask for a suite name" do
          stub_default_suite_name
          tddium.should_not_receive(:ask).with(Tddium::Text::Prompt::SUITE_NAME % SAMPLE_APP_NAME)
          run_suite(tddium)
        end

        it "should not look for the current ruby version" do
          tddium.should_not_receive(:`).with("ruby -v")
          run_suite(tddium)
        end

        it "should display '#{Tddium::Text::Process::EXISTING_SUITE}'" do
          tddium.should_receive(:say).with(Tddium::Text::Process::EXISTING_SUITE % tddium.send(:format_suite_details, SAMPLE_SUITE_RESPONSE))
          run_suite(tddium)
        end

        it "should check if the user wants to update the suite" do
          tddium.should_receive(:ask).with(Tddium::Text::Prompt::UPDATE_SUITE, anything)
          run_suite(tddium)
        end

        context "user wants to update the suite" do
          before(:each) do
            tddium.stub(:ask).with(Tddium::Text::Prompt::UPDATE_SUITE, anything).and_return(Tddium::Text::Prompt::Response::YES)
          end
          it_behaves_like "prompting for suite configuration" do
            let(:current) { SAMPLE_SUITE_RESPONSE }
          end
          it "should PUT to /suites/#{SAMPLE_SUITE_ID}" do
            call_api_should_receive(:method=>:put, :path=>"#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}")
            run_suite(tddium)
          end
        end

        it_should_behave_like "sending the api key"
        it_should_behave_like "an unsuccessful api call"
      end

      it_should_behave_like "an unsuccessful api call"
    end
  end

  describe "#version" do
    it "should print the version" do
      tddium.should_receive(:say).with(TddiumVersion::VERSION)
      run_version(tddium)
    end
  end
end
