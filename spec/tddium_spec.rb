=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require 'spec_helper'

describe Tddium do
  include FakeFS::SpecHelpers
  include TddiumSpecHelpers

  DEFAULT_APP_NAME = "tddelicious"
  DEFAULT_BRANCH_NAME = "test"
  DEFAULT_SUITE_ID = 66
  DEFAULT_API_KEY = "afb12412bdafe124124asfasfabebafeabwbawf1312342erbfasbb"
  DEFAULT_CALL_API_ERROR = [1, 501, "an error"]
  DEFAULT_EMAIL = "someone@example.com"
  DEFAULT_PASSWORD = "foobar"
  DEFAULT_LICENSE_TEXT = "LICENSE"

  def run(tddium, options = {:environment => "test"})
    send("run_#{example.example_group.ancestors.map(&:description)[-2][1..-1]}", tddium, options)
  end

  def run_suite(tddium, options = {:environment => "test"})
    stub_cli_options(tddium, options)
    tddium.suite
  end

  def run_spec(tddium, options = {:environment => "test"})
    stub_cli_options(tddium, options)
    tddium.spec
  end

  def run_status(tddium, options = {:environment => "test"})
    stub_cli_options(tddium, options)
    tddium.status
  end

  def run_account(tddium, options = {:environment => "test"})
    stub_cli_options(tddium, options)
    tddium.account
  end

  def stub_cli_options(tddium, options = {})
    tddium.stub(:options).and_return(options)
  end

  def suite_name_prompt(default = default_suite_name)
    "Enter a suite name or press 'Return'. Using '#{default}' by default:"
  end

  def default_suite_name
    "#{DEFAULT_APP_NAME}/#{DEFAULT_BRANCH_NAME}"
  end

  def stub_default_suite_name(tddium, default_app_name = DEFAULT_APP_NAME, default_branch_name = DEFAULT_BRANCH_NAME)
    Dir.stub(:pwd).and_return(default_app_name)
    stub_git_branch(tddium, default_branch_name)
  end

  def stub_ruby_version(tddium, ruby_version = "1.9.2")
    tddium.stub(:`).with("ruby -v").and_return("ruby #{ruby_version} (2010-08-16 patchlevel 302) [i686-darwin10.5.0]")
  end

  def stub_git_branch(tddium, default_branch_name = DEFAULT_BRANCH_NAME)
    tddium.stub(:`).with("git symbolic-ref HEAD").and_return(default_branch_name)
  end

  def stub_call_api_response(method, path, *response)
    options = extract_options!(response, :and_return, :and_yield)
    options[:and_yield] = true unless options[:and_yield] == false
    result = tddium_client.stub(:call_api).with(method, path, anything, anything)
    result = result.and_yield(response.first) if options[:and_yield]
    result.and_return(options[:and_return] || DEFAULT_CALL_API_ERROR)
    response.each_with_index do |current_response, index|
      result = result.and_yield(current_response) unless index.zero? || !options[:and_yield]
    end
  end

  def extract_options!(array, *option_keys)
    is_options = false
    option_keys.each do |option_key|
      is_options ||= array.last.include?(option_key.to_sym)
    end
    (array.last.is_a?(Hash) && is_options) ? array.pop : {}
  end

  def stub_defaults
    tddium.stub(:say)
    stub_git_branch(tddium)
    stub_tddium_client
    create_file(File.join(".git", "something"), "something")
  end

  def stub_config_file(options = {})
    params = {}
    params.merge!(:branches => {DEFAULT_BRANCH_NAME => DEFAULT_SUITE_ID}) if options[:branches]
    params.merge!(:api_key => (options[:api_key].is_a?(String)) ? options[:api_key] : DEFAULT_API_KEY) if options[:api_key]
    json = params.to_json unless params.empty?
    create_file(".tddium.test", json)
  end

  def stub_git_push(tddium)
    tddium.stub(:`).with(/^git push/)
  end

  def stub_sleep(tddium)
    tddium.stub(:sleep).with(Tddium::Default::SLEEP_TIME_BETWEEN_POLLS)
  end

  def call_api_should_receive(options = {})
    params = [options[:method] || anything, options[:path] || anything, options[:params] || anything, (options[:api_key] || options[:api_key] == false) ? options[:api_key] : anything]
    tddium_client.stub(:call_api).with(*params)                       # To prevent the yield
    tddium_client.should_receive(:call_api).with(*params).and_return(DEFAULT_CALL_API_ERROR)
  end

  def stub_tddium_client
    TddiumClient.stub(:new).and_return(tddium_client)
    tddium_client.stub(:environment).and_return(:test)
    tddium_client.stub(:call_api).and_return(DEFAULT_CALL_API_ERROR)
  end

  let(:tddium) { Tddium.new }
  let(:tddium_client) { mock(TddiumClient).as_null_object }

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

  shared_examples_for ".tddium.test file is missing or corrupt" do
    context ".tddium.test file is missing" do
      before do
        FileUtils.rm_rf(".tddium.test")
      end

      it "should tell the user '#{Tddium::Text::Error::NOT_INITIALIZED}'" do
        tddium.should_receive(:say).with(Tddium::Text::Error::NOT_INITIALIZED)
        run(tddium)
      end
    end

    context ".tddium.test file is corrupt" do
      before do
        create_file(".tddium.test", "corrupt file")
      end

      it "should tell the user '#{Tddium::Text::Error::INVALID_TDDIUM_FILE % 'test'}'" do
        tddium.should_receive(:say).with(Tddium::Text::Error::INVALID_TDDIUM_FILE % 'test')
        run(tddium)
      end
    end
  end

  shared_examples_for "suite has not been initialized" do
    context ".tddium.test file is missing" do
      before do
        stub_config_file(:api_key => true)
      end

      it "should tell the user '#{Tddium::Text::Error::NO_SUITE_EXISTS % DEFAULT_BRANCH_NAME}'" do
        tddium.should_receive(:say).with(Tddium::Text::Error::NO_SUITE_EXISTS % DEFAULT_BRANCH_NAME)
        run(tddium)
      end
    end
  end

  shared_examples_for "sending the api key" do
    it "should call the api with the api key" do
      call_api_should_receive(:api_key => DEFAULT_API_KEY)
      run(tddium)
    end
  end

  shared_examples_for "an unsuccessful api call" do
    it "should show the error" do
      tddium_client.stub(:call_api).and_return(DEFAULT_CALL_API_ERROR)
      tddium.should_receive(:say).with(DEFAULT_CALL_API_ERROR[2])
      run(tddium)
    end
  end

  shared_examples_for "getting the current suite from the API" do
    it "should send a 'GET' request to '#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}'" do
      call_api_should_receive(:method => :get, :path => "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}")
      run(tddium)
    end
  end

  describe "#suite" do
    before do
      stub_defaults
      stub_config_file(:api_key => true)
      stub_ruby_version(tddium)
      tddium.stub(:ask).and_return("")
      create_file("~/.ssh/id_rsa.pub", "ssh-rsa blah")
    end

    it "should ask the user for their ssh key" do
      tddium.should_receive(:ask).with(Tddium::Text::Prompt::SSH_KEY % Tddium::Default::SSH_FILE)
      run_suite(tddium)
    end

    it "should ask for a test file pattern" do
      tddium.should_receive(:ask).with(Tddium::Text::Prompt::TEST_PATTERN % Tddium::Default::TEST_PATTERN)
      run_suite(tddium)
    end

    context "using defaults" do
      it "should send the default values to the API" do
        call_api_should_receive(:params => {:suite => hash_including(:ssh_key => "ssh-rsa blah", :test_pattern => "**/*_spec.rb")})
        run_suite(tddium)
      end
    end

    context "passing arguments" do
      let(:ssh_key_file) { "~/.ssh/blah.txt" }
      let(:cli_args) { { :ssh_key => ssh_key_file, :test_pattern => "**/*_test.rb", :environment => "test" } }
      before do
        create_file(ssh_key_file, "ssh-rsa 1234")
      end

      it "should POST the passed in values to the API" do
        call_api_should_receive(:params => {:suite => hash_including(:ssh_key => "ssh-rsa 1234", :test_pattern => "**/*_test.rb")})
        run_suite(tddium, cli_args)
      end

    end

    context "interactive mode" do
      before do
        ssh_key_file = "~/.ssh/foo.txt"
        tddium.stub(:ask).with(Tddium::Text::Prompt::SSH_KEY % Tddium::Default::SSH_FILE).and_return(ssh_key_file)
        tddium.stub(:ask).with(Tddium::Text::Prompt::TEST_PATTERN % Tddium::Default::TEST_PATTERN).and_return("**/*_selenium.rb")
        create_file(ssh_key_file, "ssh-rsa 65431")
      end

      it "should POST the passed in values to the API" do
        call_api_should_receive(:params => {:suite => hash_including(:ssh_key => "ssh-rsa 65431", :test_pattern => "**/*_selenium.rb")})
        run_suite(tddium)
      end
    end
    
    it_should_behave_like "set the default environment"
    it_should_behave_like "sending the api key"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium.test file is missing or corrupt"

    context "suite has not yet been registered" do
      it "should ask for a suite name" do
        stub_default_suite_name(tddium)
        tddium.should_receive(:ask).with(suite_name_prompt)
        run_suite(tddium)
      end

      it "should send a 'POST' request to '#{Tddium::Api::Path::SUITES}'" do
        call_api_should_receive(:method => :post, :path => Tddium::Api::Path::SUITES)
        run_suite(tddium)
      end

      it "should post the current ruby version to the API" do
        stub_ruby_version(tddium, "1.9.2")
        call_api_should_receive(:params => {:suite => hash_including(:ruby_version => "1.9.2")})
        run_suite(tddium)
      end

      context "using defaults" do
        before do
          stub_default_suite_name(tddium)
        end

        it "should POST the default values to the API" do
          call_api_should_receive(:params => {:suite => hash_including(:suite_name => default_suite_name)})
          run_suite(tddium)
        end
      end

      context "passing arguments" do
        let(:cli_args) { { :name => "my_suite_name", :environment => "test" } }

        it "should POST the passed in values to the API" do
          call_api_should_receive(:params => {:suite => hash_including(:suite_name => "my_suite_name")})
          run_suite(tddium, cli_args)
        end
      end

      context "interactive mode" do
        before do
          tddium.stub(:ask).with(suite_name_prompt).and_return("foobar")
          stub_default_suite_name(tddium)
        end

        it "should POST the passed values to the API" do
          call_api_should_receive(:params => {:suite => hash_including(:suite_name => "foobar")})
          run_suite(tddium)
        end
      end

      context "API response successful" do
        before do
          response = {"suite"=>{"id"=>DEFAULT_SUITE_ID}}
          stub_call_api_response(:post, Tddium::Api::Path::SUITES, response)
          tddium.stub(:`).with(/^git remote/)
          stub_git_push(tddium)
        end

        it "should remove any existing remotes named 'tddium'" do
          tddium.should_receive(:`).with("git remote rm tddium")
          run_suite(tddium)
        end

        it "should add a new remote called 'tddium'" do
          stub_default_suite_name(tddium)
          tddium.should_receive(:`).with("git remote add tddium ssh://git@api.tddium.com/home/git/repo/#{DEFAULT_APP_NAME}")
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

          it "should create '.tddium.test' and write the suite_id and branch name" do
            run_suite(tddium)
            tddium_file = File.open(".tddium.test") { |file| file.read }
            JSON.parse(tddium_file)["branches"]["oaktree"].should == DEFAULT_SUITE_ID
          end
        end
      end

      it_should_behave_like "an unsuccessful api call"
    end

    context "suite has already been registered" do
      before do
        stub_config_file(:api_key => true, :branches => true)
      end

      context "'GET #{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}' is successful" do
        before do
          response = {
            "suite" => {
              "test_pattern" => "**/*_test.rb",
              "id" => DEFAULT_SUITE_ID,
              "ssh_key" => "ssh-rsa AAAABb/wVQ== someone@gmail.com\n",
            }
          }
          stub_call_api_response(:get, "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}", response)
        end

        it "should not ask for a suite name" do
          stub_default_suite_name(tddium)
          tddium.should_not_receive(:ask).with(suite_name_prompt)
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

        it "should send a 'PUT' request to '#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}'" do
          call_api_should_receive(:method => :put, :path => "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}")
          run_suite(tddium)
        end

        context "'PUT #{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}' is successful" do
          before { stub_call_api_response(:put, "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}", {}) }
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

  describe "#spec" do
    before do
      stub_defaults
      stub_config_file(:api_key => true, :branches => true)
      stub_git_push(tddium)
    end

    it_should_behave_like "set the default environment"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium.test file is missing or corrupt"
    it_should_behave_like "suite has not been initialized"

    it "should push the latest code to tddium" do
      tddium.should_receive(:`).with("git push #{Tddium::Git::REMOTE_NAME} #{DEFAULT_BRANCH_NAME}")
      run_spec(tddium)
    end

    it_should_behave_like "getting the current suite from the API"
    it_should_behave_like "sending the api key"

    context "'GET #{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}' is successful" do
      before do
        response = {"suite"=>{"test_pattern"=>"**/*_spec.rb", "id"=>DEFAULT_SUITE_ID, "suite_name"=>"tddium/demo", "ssh_key"=>"ssh-rsa AAAABb/wVQ== someone@gmail.com\n", "ruby_version"=>"1.8.7"}, "status"=>0}
        stub_call_api_response(:get, "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}", response)
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
        let(:session_id) {7}
        before do
          response = {"session"=>{"id"=>session_id}}
          stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}", response)
        end

        it "should send a 'POST' request to '#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}'" do
          call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}$/)
          run_spec(tddium)
        end

        it_should_behave_like "sending the api key"

        it "should POST the names of the file names extracted from the suite's test_pattern" do
          current_dir = Dir.pwd
          call_api_should_receive(:params => {:suite_id => DEFAULT_SUITE_ID,
                                  :tests => [{:test_name => "#{current_dir}/spec/cat_spec.rb"},
                                             {:test_name => "#{current_dir}/spec/dog_spec.rb"},
                                             {:test_name => "#{current_dir}/spec/mouse_spec.rb"}]})
          run_spec(tddium)
        end

        context "'POST #{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}' is successful" do
          before do
            response = {"added"=>0, "existing"=>1, "errors"=>0, "status"=>0}
            stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}", response)
          end

          it "should send a 'POST' request to '#{Tddium::Api::Path::START_TEST_EXECUTIONS}'" do
            call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/)
            run_spec(tddium)
          end

          it_should_behave_like "sending the api key"

          context "'POST #{Tddium::Api::Path::START_TEST_EXECUTIONS}' is successful" do
            let(:get_test_executions_response) { {"report"=>"http://api.tddium.com/1/sessions/7/test_executions/report", "tests"=>{"spec/mouse_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:07:06Z", "test_script_id"=>26, "instance_id"=>nil, "session_id"=>7, "id"=>3, "status"=>"pending", "start_time"=>"2011-03-04T07:07:06Z"}, "spec/pig_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>nil, "test_script_id"=>27, "instance_id"=>nil, "session_id"=>7, "id"=>4, "status"=>"started", "start_time"=>"2011-03-04T07:08:06Z"}, "spec/dog_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:06:12Z", "test_script_id"=>25, "instance_id"=>nil, "session_id"=>7, "id"=>2, "status"=>"failed", "start_time"=>"2011-03-04T07:06:06Z"}, "spec/cat_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:05:12Z", "test_script_id"=>24, "instance_id"=>nil, "session_id"=>7, "id"=>1, "status"=>"passed", "start_time"=>"2011-03-04T07:05:06Z"}}, "status"=>0} }
            before do
              response = {"started"=>1, "status"=>0}
              stub_call_api_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::START_TEST_EXECUTIONS}", response)
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
                tddium.should_receive(:say).with(Tddium::Text::Process::CHECK_TEST_REPORT % "http://api.tddium.com/1/sessions/7/test_executions/report")
                run_spec(tddium)
              end

              it "should show the user the time taken" do
                tddium.should_receive(:say).with(/^#{Tddium::Text::Process::FINISHED_TEST % "[\\d\\.]+"}$/)
                run_spec(tddium)
              end
            end

            context "user presses 'Ctrl-C' during the process" do
              before do
                stub_call_api_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::TEST_EXECUTIONS}", get_test_executions_response)
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
                get_test_executions_response_all_finished = {"report"=>"http://api.tddium.com/1/sessions/7/test_executions/report", "tests"=>{"spec/mouse_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:07:06Z", "test_script_id"=>26, "instance_id"=>nil, "session_id"=>7, "id"=>3, "status"=>"pending", "start_time"=>"2011-03-04T07:07:06Z"}, "spec/pig_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:07:06Z", "test_script_id"=>27, "instance_id"=>nil, "session_id"=>7, "id"=>4, "status"=>"error", "start_time"=>"2011-03-04T07:08:06Z"}, "spec/dog_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:06:12Z", "test_script_id"=>25, "instance_id"=>nil, "session_id"=>7, "id"=>2, "status"=>"failed", "start_time"=>"2011-03-04T07:06:06Z"}, "spec/cat_spec.rb"=>{"result"=>nil, "usage"=>nil, "end_time"=>"2011-03-04T07:05:12Z", "test_script_id"=>24, "instance_id"=>nil, "session_id"=>7, "id"=>1, "status"=>"passed", "start_time"=>"2011-03-04T07:05:06Z"}}, "status"=>0}
                stub_call_api_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::TEST_EXECUTIONS}", get_test_executions_response, get_test_executions_response_all_finished)
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
      suites_response = {"suites"=>[{"created_at"=>"2011-03-11T06:23:40Z", "updated_at"=>"2011-03-11T06:25:51Z", "test_pattern"=>"**/*_spec.rb", "id"=>66, "user_id"=>3, "suite_name"=>"tddium/demo", "ssh_key"=>"ssh-rsa AAAABb/wVQ== someone@gmail.com\n", "ruby_version"=>"1.8.7"}], "status"=>0}
      stub_call_api_response(:get, Tddium::Api::Path::SUITES, suites_response)
      sessions_response = {"status"=>0, "sessions"=>[{"created_at"=>"2011-03-11T08:43:02Z", "updated_at"=>"2011-03-11T08:43:02Z", "id"=>1, "user_id"=>3}]}
      stub_call_api_response(:get, Tddium::Api::Path::SESSIONS, sessions_response)
    end

    it_should_behave_like "set the default environment"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium.test file is missing or corrupt"
    it_should_behave_like "suite has not been initialized"

    context "'GET #{Tddium::Api::Path::SUITES}' is successful" do
      it "should show the user the suite name" do
        tddium.should_receive(:say).with("  Suite name: tddium/demo")
        run_status(tddium)
      end

      it "should show the user the ssh key" do
        tddium.should_receive(:say).with("  Ssh key: ssh-rsa AAAABb/wVQ== someone@gmail.com\n")
        run_status(tddium)
      end

      it "should show the user the test pattern" do
        tddium.should_receive(:say).with("  Test pattern: **/*_spec.rb")
        run_status(tddium)
      end

      it "should show the user the ruby version" do
        tddium.should_receive(:say).with("  Ruby version: 1.8.7")
        run_status(tddium)
      end

      it "should not show the user the created at timestamp" do
        tddium.should_not_receive(:say).with(/Created at/)
        run_status(tddium)
      end

      it "should not show the user the updated at timestamp" do
        tddium.should_not_receive(:say).with(/Updated at/)
        run_status(tddium)
      end

      it "should not show the user the user id" do
        tddium.should_not_receive(:say).with(/User id/)
        run_status(tddium)
      end

      it "should not show the user the suite id" do
        tddium.should_not_receive(:say).with(/id/)
        run_status(tddium)
      end
    end

    it_should_behave_like "an unsuccessful api call"
  end

  describe "#account" do
    before do
      stub_defaults
      tddium.stub(:ask).and_return("")
      HighLine.stub(:ask).and_return("")
      create_file(File.join(File.dirname(__FILE__), "..", Tddium::License::FILE_NAME), DEFAULT_LICENSE_TEXT)
    end
    it_should_behave_like "set the default environment"

    context "there is a tddium config file with an api key" do
      before {stub_config_file(:api_key => "some api key")}

      shared_examples_for "showing the user's details" do
        before do
          stub_call_api_response(:get, Tddium::Api::Path::USERS, {"email" => DEFAULT_EMAIL, "created_at" => "2011-03-11T08:43:02Z"})
        end

        it "should show the user's email address" do
          tddium.should_receive(:say).with(DEFAULT_EMAIL)
          run_account(tddium)
        end

        it "should show the user's account creation date" do
          tddium.should_receive(:say).with("2011-03-11T08:43:02Z")
          run_account(tddium)
        end        
      end

      it "should send a 'GET' request to '#{Tddium::Api::Path::USERS}'" do
        call_api_should_receive(:method => :get, :path => /#{Tddium::Api::Path::USERS}$/)
        run_account(tddium)
      end
     
      context "which is valid" do
        it_should_behave_like "showing the user's details"
      end

      context "which is invalid" do
        shared_examples_for "a password prompt" do
          context "--password was not passed in" do
            it "should prompt for a password or confirmation" do
              highline = mock(HighLine)
              HighLine.should_receive(:ask).with(password_prompt).and_yield(highline)
              highline.should_receive(:echo=).with("*")
              run_account(tddium)
            end
          end
          context "--password was passed in" do
            it "should not prompt for a password or confirmation" do
              HighLine.should_not_receive(:ask).with(password_prompt)
              run_account(tddium, :password => DEFAULT_PASSWORD)
            end
          end
        end

        context "--email was not passed in" do
          it "should prompt for the user's email address" do
            tddium.should_receive(:ask).with(Tddium::Text::Prompt::EMAIL)
            run_account(tddium)
          end
        end

        context "--email was passed in" do
          it "should not prompt for the user's email address" do
            tddium.should_not_receive(:ask).with(Tddium::Text::Prompt::EMAIL)
            run_account(tddium, :email => DEFAULT_EMAIL)
          end
        end

        it_should_behave_like "a password prompt" do
          let(:password_prompt) {Tddium::Text::Prompt::PASSWORD}
        end

        it "should try to sign in the user with their email & password" do
          tddium.stub(:ask).with(Tddium::Text::Prompt::EMAIL).and_return(DEFAULT_EMAIL)
          HighLine.stub(:ask).with(Tddium::Text::Prompt::PASSWORD).and_return(DEFAULT_PASSWORD)
          call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::SIGN_IN}$/, :params => {:user => {:email => DEFAULT_EMAIL, :password => DEFAULT_PASSWORD}}, :api_key => false)
          run_account(tddium)
        end

        shared_examples_for "writing the api key to the .tddium file" do
          it "should write the api key to the .tddium file" do
            run_account(tddium)
            tddium_file = File.open(".tddium.test") { |file| file.read }
            JSON.parse(tddium_file)["api_key"].should == DEFAULT_API_KEY
          end
        end

        context "the user is signed in correctly with their email & password" do
          before{stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, {"api_key" => DEFAULT_API_KEY})}
          it_should_behave_like "writing the api key to the .tddium file"
          it_should_behave_like "showing the user's details"         
        end
        
        context "the user did not sign in correctly" do
          let(:call_api_result) {[403, "Forbidden"]}
          context "because their password was incorrect (i.e. an email already exists)" do
            before{stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, :and_yield => false, :and_return => call_api_result.unshift(Tddium::Api::ErrorCode::INCORRECT_PASSWORD))}
            it "should tell the user that the email address has already been taken" do
              tddium.should_receive(:say).with(Tddium::Text::Process::ACCOUNT_TAKEN)
              run_account(tddium)
            end
          end
          context "because the email did not exist (i.e. no account with this email)" do
            before{stub_call_api_response(:post, Tddium::Api::Path::SIGN_IN, :and_yield => false, :and_return => call_api_result.unshift(Tddium::Api::ErrorCode::EMAIL_NOT_FOUND))}

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
              it "should show the user the license" do
                tddium.should_receive(:say).with(DEFAULT_LICENSE_TEXT)
                run_account(tddium)
              end

              it "should ask the user to accept the license" do
                tddium.should_receive(:ask).with(Tddium::Text::Prompt::LICENSE_AGREEMENT)
                run_account(tddium)
              end

              context "accepting the license" do
                before do
                  tddium.stub(:ask).with(Tddium::Text::Prompt::LICENSE_AGREEMENT).and_return(Tddium::Text::Prompt::Response::AGREE_TO_LICENSE)
                  tddium.stub(:ask).with(Tddium::Text::Prompt::EMAIL).and_return(DEFAULT_EMAIL)
                end
                it "should send a 'POST' request to '#{Tddium::Api::Path::USERS}' with the user's email address and password" do
                  call_api_should_receive(:method => :post, :path => /#{Tddium::Api::Path::USERS}$/, :params => {:user => {:email => DEFAULT_EMAIL, :password => ""}}, :api_key => false)
                  run_account(tddium)
                end
                context "'POST #{Tddium::Api::Path::USERS}' is successful" do
                  before{stub_call_api_response(:post, Tddium::Api::Path::USERS, {"api_key" => DEFAULT_API_KEY})}
                  it_should_behave_like "writing the api key to the .tddium file"
                end
              end
            end
          end
        end
      end
    end
  end
end
