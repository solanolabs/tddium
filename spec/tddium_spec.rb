=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require 'spec_helper'

describe Tddium do
  include FakeFS::SpecHelpers
  include TddiumSpecHelpers

  SAMPLE_API_KEY = "afb12412bdafe124124asfasfabebafeabwbawf1312342erbfasbb"
  SAMPLE_APP_NAME = "tddelicious"
  SAMPLE_BRANCH_NAME = "test"
  SAMPLE_BUNDLER_VERSION = "1.10.10"
  SAMPLE_CALL_API_RESPONSE = [0, 200, nil]
  SAMPLE_CALL_API_ERROR = [1, 501, "an error"]
  SAMPLE_DATE_TIME = "2011-03-11T08:43:02Z"
  SAMPLE_EMAIL = "someone@example.com"
  SAMPLE_INVITATION_TOKEN = "TZce3NueiXp2lMTmaeRr"
  SAMPLE_GIT_REPO_URI = "ssh://git@api.tddium.com/home/git/repo/#{SAMPLE_APP_NAME}"
  SAMPLE_LICENSE_TEXT = "LICENSE"
  SAMPLE_PASSWORD = "foobar"
  SAMPLE_REPORT_URL = "http://api.tddium.com/1/sessions/1/test_executions/report"
  SAMPLE_RUBYGEMS_VERSION = "1.3.7"
  SAMPLE_RUBY_VERSION = "1.8.7"
  SAMPLE_RECURLY_URL = "https://tddium.recurly.com/account/1"
  SAMPLE_SESSION_ID = 1
  SAMPLE_SUITE_ID = 1
  SAMPLE_SUITES_RESPONSE = {"suites" => [{"repo_name" => SAMPLE_APP_NAME, "branch" => SAMPLE_BRANCH_NAME, "id" => SAMPLE_SUITE_ID}]}
  SAMPLE_TDDIUM_CONFIG_FILE = ".tddium.test"
  SAMPLE_TEST_PATTERN = "**/*_spec.rb"
  SAMPLE_USER_RESPONSE = {"user"=> {"api_key" => SAMPLE_API_KEY, "email" => SAMPLE_EMAIL, "created_at" => SAMPLE_DATE_TIME, "recurly_url" => SAMPLE_RECURLY_URL}}

  def call_api_should_receive(options = {})
    params = [options[:method] || anything, options[:path] || anything, options[:params] || anything, (options[:api_key] || options[:api_key] == false) ? options[:api_key] : anything]
    tddium_client.stub(:call_api).with(*params)                       # To prevent the yield
    tddium_client.should_receive(:call_api).with(*params).and_return(SAMPLE_CALL_API_ERROR)
  end

  def extract_options!(array, *option_keys)
    is_options = false
    option_keys.each do |option_key|
      is_options ||= array.last.include?(option_key.to_sym)
    end
    (array.last.is_a?(Hash) && is_options) ? array.pop : {}
  end

  def run(tddium, options = {:environment => "test"})
    send("run_#{example.example_group.ancestors.map(&:description)[-2][1..-1]}", tddium, options)
  end

  [:suite, :spec, :status, :account, :login, :logout].each do |method|
    define_method("run_#{method}") do |tddium, *params|
      options = params.first || {}
      options[:environment] = "test" unless options.has_key?(:environment)
      stub_cli_options(tddium, options)
      tddium.send(method)
    end
  end

  def stub_bundler_version(tddium, version = SAMPLE_BUNDLER_VERSION)
    tddium.stub(:`).with("bundle -v").and_return("Bundler version #{version}")
  end

  def stub_call_api_response(method, path, *response)
    options = extract_options!(response, :and_return, :and_yield)
    options[:and_yield] = true unless options[:and_yield] == false
    result = tddium_client.stub(:call_api).with(method, path, anything, anything)
    result = result.and_yield(response.first) if options[:and_yield]
    result.and_return(options[:and_return] || SAMPLE_CALL_API_ERROR)
    response.each_with_index do |current_response, index|
      result = result.and_yield(current_response) unless index.zero? || !options[:and_yield]
    end
  end

  def stub_cli_options(tddium, options = {})
    tddium.stub(:options).and_return(options)
  end

  def stub_config_file(options = {})
    params = {}
    params.merge!(:branches => (options[:branches].is_a?(Hash)) ? options[:branches] : {SAMPLE_BRANCH_NAME => SAMPLE_SUITE_ID}) if options[:branches]
    params.merge!(:api_key => (options[:api_key].is_a?(String)) ? options[:api_key] : SAMPLE_API_KEY) if options[:api_key]
    json = params.to_json unless params.empty?
    create_file(SAMPLE_TDDIUM_CONFIG_FILE, json)
  end

  def stub_default_suite_name
    Dir.stub(:pwd).and_return(SAMPLE_APP_NAME)
  end

  def stub_defaults
    tddium.stub(:say)
    stub_git_branch(tddium)
    stub_tddium_client
    create_file(File.join(".git", "something"), "something")
  end

  def stub_git_branch(tddium, default_branch_name = SAMPLE_BRANCH_NAME)
    tddium.stub(:`).with("git symbolic-ref HEAD").and_return(default_branch_name)
  end

  def stub_git_push(tddium)
    tddium.stub(:`).with(/^git push/)
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

  def stub_tddium_client
    TddiumClient.stub(:new).and_return(tddium_client)
    tddium_client.stub(:environment).and_return(:test)
    tddium_client.stub(:call_api).and_return(SAMPLE_CALL_API_ERROR)
  end

  let(:tddium) { Tddium.new }
  let(:tddium_client) { mock(TddiumClient).as_null_object }


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
      tddium_client.stub(:call_api).and_return(SAMPLE_CALL_API_ERROR)
      tddium.should_receive(:say).with(SAMPLE_CALL_API_ERROR[2])
      run(tddium)
    end
  end

  shared_examples_for "git repo has not been initialized" do
    context "git repo has not been initialized" do
      before do
        FileUtils.rm_rf(".git")
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

  shared_examples_for "logging in a user" do
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
    end

    context "the user logs in successfully with their email and password" do
      before{stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, {"api_key" => SAMPLE_API_KEY})}
      it_should_behave_like "writing the api key to the .tddium file"
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

  shared_examples_for "writing the api key to the .tddium file" do
    it "should write the api key to the .tddium file" do
      run(tddium)
      tddium_file = File.open(SAMPLE_TDDIUM_CONFIG_FILE) { |file| file.read }
      JSON.parse(tddium_file)["api_key"].should == SAMPLE_API_KEY
    end
  end

  describe "#account" do
    before do
      stub_defaults
      tddium.stub(:ask).and_return("")
      HighLine.stub(:ask).and_return("")
      create_file(File.join(File.dirname(__FILE__), "..", Tddium::License::FILE_NAME), SAMPLE_LICENSE_TEXT)
      create_file(Tddium::Default::SSH_FILE, "ssh-rsa blah")
    end

    it_should_behave_like "set the default environment"

    context "the user is already logged in" do
      before do
        stub_config_file(:api_key => SAMPLE_API_KEY)
        stub_call_api_response(:get, Tddium::Api::Path::USERS, SAMPLE_USER_RESPONSE)
      end

      it "should show the user's email address" do
        tddium.should_receive(:say).with(SAMPLE_EMAIL)
        run_account(tddium)
      end

      it "should show the user's account creation date" do
        tddium.should_receive(:say).with(SAMPLE_DATE_TIME)
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

        context "--ssh-key-file is not supplied" do
          it "should prompt the user for their ssh key file" do
            tddium.should_receive(:ask).with(Tddium::Text::Prompt::SSH_KEY % Tddium::Default::SSH_FILE)
            run_account(tddium)
          end
        end

        context "--ssh-key-file is supplied" do
          it "should not prompt the user for their ssh key file" do
            tddium.should_not_receive(:ask).with(Tddium::Text::Prompt::SSH_KEY % Tddium::Default::SSH_FILE)
            run_account(tddium, :ssh_key_file => Tddium::Default::SSH_FILE)
          end
        end

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
              before { stub_call_api_response(:post, Tddium::Api::Path::USERS, :and_yield => false, :and_return => [Tddium::Api::ErrorCode::INVALID_INVITATION, 409, "Invitation is invalid"]) }
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
    it_should_behave_like "logging in a user"

    context "user is already logged in" do
      before do
        stub_config_file(:api_key => SAMPLE_API_KEY)
        stub_call_api_response(:get, Tddium::Api::Path::USERS, :and_yield => false, :and_return => SAMPLE_CALL_API_RESPONSE)
      end

      it "should show the user: '#{Tddium::Text::Process::ALREADY_LOGGED_IN}'" do
        tddium.should_receive(:say).with(Tddium::Text::Process::ALREADY_LOGGED_IN)
        run_login(tddium)
      end
    end

    context "the user logs in successfully" do
      before{stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, {})}
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
    before { tddium.stub(:say) }

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
      stub_git_push(tddium)
    end

    it_should_behave_like "set the default environment"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium file is missing or corrupt"
    it_should_behave_like "suite has not been initialized"

    it "should push the latest code to tddium" do
      tddium.should_receive(:`).with("git push #{Tddium::Git::REMOTE_NAME} #{SAMPLE_BRANCH_NAME}")
      run_spec(tddium)
    end

    it_should_behave_like "getting the current suite from the API"
    it_should_behave_like "sending the api key"

    context "'GET #{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}' is successful" do
      before do
        response = {"suite"=>{"test_pattern"=>SAMPLE_TEST_PATTERN, "id"=>SAMPLE_SUITE_ID, "suite_name"=>"tddium/demo", "ruby_version"=>SAMPLE_RUBY_VERSION}}
        stub_call_api_response(:get, "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}", response)
        create_file("spec/mouse_spec.rb")
        create_file("spec/cat_spec.rb")
        create_file("spec/dog_spec.rb")
      end

      it "should send a 'POST' request to '#{Tddium::Api::Path::SESSIONS}'" do
        call_api_should_receive(:method => :post, :path => Tddium::Api::Path::SESSIONS)
        run_spec(tddium)
      end

      it_should_behave_like "sending the api key"

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

        it "should POST the names of the file names extracted from the suite's test_pattern" do
          current_dir = Dir.pwd
          call_api_should_receive(:params => {:suite_id => SAMPLE_SUITE_ID,
                                  :tests => [{:test_name => "#{current_dir}/spec/cat_spec.rb"},
                                             {:test_name => "#{current_dir}/spec/dog_spec.rb"},
                                             {:test_name => "#{current_dir}/spec/mouse_spec.rb"}]})
          run_spec(tddium)
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

          it_should_behave_like "sending the api key"

          context "'POST #{Tddium::Api::Path::START_TEST_EXECUTIONS}' is successful" do
            let(:get_test_executions_response) { {"report"=>SAMPLE_REPORT_URL, "tests"=>{"spec/mouse_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"pending"}, "spec/pig_spec.rb"=>{"end_time"=>nil, "status"=>"started"}, "spec/dog_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"failed"}, "spec/cat_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"passed"}}} }
            before do
              response = {"started"=>1, "status"=>0}
              stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{SAMPLE_SESSION_ID}/#{Tddium::Api::Path::START_TEST_EXECUTIONS}", response)
            end

            it "should tell the user to '#{Tddium::Text::Process::TERMINATE_INSTRUCTION}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::TERMINATE_INSTRUCTION)
              run_spec(tddium)
            end

            it "should tell the user '#{Tddium::Text::Process::STARTING_TEST % 3}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::STARTING_TEST % 3)
              run_spec(tddium)
            end

            it "should send a 'GET' request to '#{Tddium::Api::Path::TEST_EXECUTIONS}'" do
              call_api_should_receive(:method => :get, :path => /#{Tddium::Api::Path::TEST_EXECUTIONS}$/)
              run_spec(tddium)
            end

            it_should_behave_like "sending the api key"

            shared_examples_for("test output summary") do
              it "should show the user a link to the report" do
                tddium.should_receive(:say).with(Tddium::Text::Process::CHECK_TEST_REPORT % SAMPLE_REPORT_URL)
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
                tddium.should_receive(:say).with("3 examples, 1 failures, 0 errors, 1 pending")
                run_spec(tddium)
              end

              it_should_behave_like("test output summary")
            end

            context "'GET #{Tddium::Api::Path::TEST_EXECUTIONS}' is successful" do
              before do
              get_test_executions_response_all_finished = {"report"=>SAMPLE_REPORT_URL, "tests"=>{"spec/mouse_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"pending"}, "spec/pig_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"error"}, "spec/dog_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"failed"}, "spec/cat_spec.rb"=>{"end_time"=>SAMPLE_DATE_TIME, "status"=>"passed"}}}
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
                tddium.should_receive(:say).with("4 examples, 1 failures, 1 errors, 1 pending")
                run_spec(tddium)
              end

              it_should_behave_like("test output summary")
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

    context "'GET #{Tddium::Api::Path::SUITES}' is successful" do
      context "returns no suites" do
        before { stub_call_api_response(:get, Tddium::Api::Path::SUITES, {"suites" => []}) }

        it "should show the user '#{Tddium::Text::Status::NO_SUITE}'" do
          tddium.should_receive(:say).with(Tddium::Text::Status::NO_SUITE)
          run_status(tddium)
        end
      end

      context "returns some suites" do
        let(:suite_attributes) { {"id"=>SAMPLE_SUITE_ID, "repo_name"=>SAMPLE_APP_NAME, "ruby_version"=>SAMPLE_RUBY_VERSION, "branch" => SAMPLE_BRANCH_NAME, "test_pattern" => SAMPLE_TEST_PATTERN, "bundler_version" => SAMPLE_BUNDLER_VERSION, "rubygems_version" => SAMPLE_RUBYGEMS_VERSION}}
        before do
          suites_response = {"suites"=>[suite_attributes], "status"=>0}
          stub_call_api_response(:get, Tddium::Api::Path::SUITES, suites_response)
        end

        it "should show all suites" do
          tddium.should_receive(:say).with(Tddium::Text::Status::ALL_SUITES % SAMPLE_APP_NAME)
          run_status(tddium)
        end

        context "without current suite" do
          before { stub_config_file(:branches => {SAMPLE_BRANCH_NAME => 0}) }
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
                sessions_response = {"status"=>0, "sessions"=>[]}
                stub_call_api_response(:get, Tddium::Api::Path::SESSIONS, sessions_response)
              end

              it "should display no active session message" do
                tddium.should_receive(:say).with(Tddium::Text::Status::NO_ACTIVE_SESSION)
                run_status(tddium)
              end
            end

            context "with some sessions" do
              let(:session_attributes) { {"id"=>SAMPLE_SESSION_ID, "user_id"=>3} }
              before do
                sessions_response = {"status"=>0, "sessions"=>[session_attributes]}
                stub_call_api_response(:get, Tddium::Api::Path::SESSIONS, sessions_response)
              end

              it "should display the active sessions prompt" do
                tddium.should_receive(:say).with(Tddium::Text::Status::ACTIVE_SESSIONS)
                run_status(tddium)
              end

              it_should_behave_like "attribute details" do
                let(:attributes_to_display) {Tddium::DisplayedAttributes::TEST_EXECUTION}
                let(:attributes_to_hide) { [/id/] }
                let(:attributes) { session_attributes }
              end
            end
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

    it_should_behave_like "set the default environment"
    it_should_behave_like "sending the api key"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium file is missing or corrupt"

    context ".tddium file contains no suites" do
      before do
        stub_default_suite_name
        stub_call_api_response(:get, Tddium::Api::Path::SUITES, {"suites" => []}, :and_return => SAMPLE_CALL_API_RESPONSE)
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
        before { tddium.stub(:ask).with(Tddium::Text::Prompt::SUITE_NAME % SAMPLE_APP_NAME).and_return("some_other_suite") }

        it "should ask for a suite name" do
          tddium.should_receive(:ask).with(Tddium::Text::Prompt::SUITE_NAME % SAMPLE_APP_NAME)
          run_suite(tddium)
        end

        it "should send a GET request with the user's entries to the API" do
          call_api_should_receive(:method => :get, :path => Tddium::Api::Path::SUITES, :params => hash_including(:repo_name => "some_other_suite"))
          run_suite(tddium)
        end
      end

      context "passing '--name=my_suite --test-pattern=**/*_selenium.rb'" do
        it "should POST request with the passed in values to the API" do
          call_api_should_receive(:method => :post, :path => Tddium::Api::Path::SUITES, :params => {:suite => hash_including(:repo_name => "my_suite", :test_pattern => "**/*_selenium.rb")})
          run_suite(tddium, :name => "my_suite", :test_pattern => "**/*_selenium.rb")
        end
      end

      context "but this user has already registered some suites" do
        before do
          stub_call_api_response(:get, Tddium::Api::Path::SUITES, SAMPLE_SUITES_RESPONSE, {"suites" => []}, :and_return => SAMPLE_CALL_API_RESPONSE)
          tddium.stub(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_APP_NAME).and_return(Tddium::Text::Prompt::Response::YES)
        end

        shared_examples_for "writing the suite to file" do
          it "should write the suite id and branch name to the .tddium file" do
            run_suite(tddium)
            tddium_file = File.open(SAMPLE_TDDIUM_CONFIG_FILE) { |file| file.read }
            JSON.parse(tddium_file)["branches"][SAMPLE_BRANCH_NAME].should == SAMPLE_SUITE_ID
          end
        end

        context "passing no cli options" do
          it "should ask the user: '#{Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_APP_NAME}' " do
            tddium.should_receive(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_APP_NAME).and_return("something")
            run_suite(tddium)
          end
        end

        context "passing --name=my_suite" do
          before do
            stub_call_api_response(:get, Tddium::Api::Path::SUITES, SAMPLE_SUITES_RESPONSE, :and_return => SAMPLE_CALL_API_RESPONSE)
          end

          it "should not ask the user if they want to use the existing suite" do
            tddium_client.should_not_receive(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % "my_suite")
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
            stub_call_api_response(:get, Tddium::Api::Path::SUITES, SAMPLE_SUITES_RESPONSE, :and_return => SAMPLE_CALL_API_RESPONSE)
          end

          it "should not send a 'POST' request to '#{Tddium::Api::Path::SUITES}'" do
            tddium_client.should_not_receive(:call_api).with(:method => :post, :path => Tddium::Api::Path::SUITES)
            run_suite(tddium)
          end

          it_should_behave_like "writing the suite to file"

          it "should show the user: '#{Tddium::Text::Status::USING_SUITE % [SAMPLE_APP_NAME, SAMPLE_BRANCH_NAME]}'" do
            tddium.should_receive(:say).with(Tddium::Text::Status::USING_SUITE % [SAMPLE_APP_NAME, SAMPLE_BRANCH_NAME])
            run_suite(tddium)
          end
        end

        context "the user does not want to use the existing suite" do
          before{ tddium.stub(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_APP_NAME).and_return("some_other_suite") }

          it "should ask for a test file pattern" do
            tddium.should_receive(:ask).with(Tddium::Text::Prompt::TEST_PATTERN % Tddium::Default::TEST_PATTERN)
            run_suite(tddium)
          end

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

          context "using defaults" do
            it "should POST the default test pattern to the API" do
              call_api_should_receive(:params => {:suite => hash_including(:test_pattern => SAMPLE_TEST_PATTERN)})
              run_suite(tddium)
            end
          end

          context "interactive mode" do
            before do
              tddium.stub(:ask).with(Tddium::Text::Prompt::USE_EXISTING_SUITE % SAMPLE_APP_NAME).and_return("foobar")
              tddium.stub(:ask).with(Tddium::Text::Prompt::TEST_PATTERN % Tddium::Default::TEST_PATTERN).and_return("**/*_test")
              stub_default_suite_name
            end

            it "should POST the user's entered values to the API" do
              call_api_should_receive(:method => :post, :params => {:suite => hash_including(:repo_name => "foobar", :test_pattern => "**/*_test")})
              run_suite(tddium)
            end
          end

          context "API response successful" do
            before do
              stub_call_api_response(:post, Tddium::Api::Path::SUITES, {"suite"=>{"id"=>SAMPLE_SUITE_ID, "git_repo_uri" => SAMPLE_GIT_REPO_URI}})
              tddium.stub(:`).with(/^git remote/)
              stub_git_push(tddium)
            end

            it_should_behave_like("writing the suite to file")

            it "should remove any existing remotes named 'tddium'" do
              tddium.should_receive(:`).with("git remote rm tddium")
              run_suite(tddium)
            end

            it "should add a new remote called '#{Tddium::Git::REMOTE_NAME}'" do
              stub_default_suite_name
              tddium.should_receive(:`).with("git remote add #{Tddium::Git::REMOTE_NAME} #{SAMPLE_GIT_REPO_URI}")
              run_suite(tddium)
            end

            context "in the branch 'oaktree'" do
              before do
                tddium.stub(:current_git_branch).and_return("oaktree")
              end

              it "should push the current git branch to tddium oaktree" do
                tddium.should_receive(:`).with("git push tddium oaktree")
                run_suite(tddium)
              end
            end
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
        before do
          response = {
            "suite" => {
              "test_pattern" => "**/*_test.rb",
              "id" => SAMPLE_SUITE_ID
            }
          }
          stub_call_api_response(:get, "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}", response)
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

        it "should prompt for a test pattern using the current test pattern as the default" do
          tddium.should_receive(:ask).with(/\*\*\/\*\_test\.rb/)
          run_suite(tddium)
        end

        it "should send a 'PUT' request to '#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}'" do
          call_api_should_receive(:method => :put, :path => "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}")
          run_suite(tddium)
        end

        context "'PUT #{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}' is successful" do
          before { stub_call_api_response(:put, "#{Tddium::Api::Path::SUITES}/#{SAMPLE_SUITE_ID}", {}) }
          it "should display '#{Tddium::Text::Process::UPDATE_SUITE}'" do
            tddium.should_receive(:say).with(Tddium::Text::Process::UPDATE_SUITE)
            run_suite(tddium)
          end
        end

        it_should_behave_like "sending the api key"
        it_should_behave_like "an unsuccessful api call"
      end

      it_should_behave_like "an unsuccessful api call"
    end
  end
end
