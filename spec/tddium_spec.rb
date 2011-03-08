require 'spec_helper'

# TODO: Test what happens if an error occurs in the POST and GET requests
describe Tddium do
  include FakeFS::SpecHelpers

  DEFAULT_APP_NAME = "tddelicious"
  DEFAULT_BRANCH_NAME = "test"
  DEFAULT_SUITE_ID = "66"
  DEFAULT_API_KEY = "afb12412bdafe124124asfasfabebafeabwbawf1312342erbfasbb"

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

  def parse_request_params
    Rack::Utils.parse_nested_query(FakeWeb.last_request.body)
  end

  def create_file(path, content = "blah")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') do |f|
      f.write(content)
    end
  end

  def register_uri_options(options = {})
    if options.is_a?(Array)
      options_array = []
      options.each do |sub_options|
        options_array << register_uri_options(sub_options)
      end
      options_array
    else
      options_for_fake_web = {:body => options[:body], :status => options[:status]}
      if options[:response]
        FakeFS.deactivate!
        response = File.open(options[:response]) { |f| f.read }
        FakeFS.activate!
        options_for_fake_web.merge!(:response => response)
      end
      options_for_fake_web
    end
  end

  def tddium_config(raw = false, environment = "test")
   unless @tddium_config
     FakeFS.deactivate!
     @tddium_config = File.read(File.join("config", "environment.yml"))
     FakeFS.activate!
   end
   raw ? @tddium_config : YAML.load(@tddium_config)[environment]
  end

  def stub_tddium_config
    create_file(File.join("config", "environment.yml"), tddium_config(true))
  end

  def stub_http_response(method, path, options = {})
    uri = URI.parse("")
    uri.host = tddium_config["api"]["host"]
    uri.scheme = tddium_config["api"]["scheme"]
    uri.port = tddium_config["api"]["port"]
    FakeWeb.register_uri(method, URI.join(uri.to_s, "#{tddium_config["api"]["version"]}/#{path}").to_s, register_uri_options(options))
  end

  def stub_defaults
    FakeWeb.clean_registry
    tddium.stub(:say)
    stub_tddium_config
    stub_git_branch(tddium)
    create_file(".git/something", "something")
  end

  def stub_config_file(without_branches = true)
    branch_params = without_branches ? {} : {:branches => {DEFAULT_BRANCH_NAME => DEFAULT_SUITE_ID}}
    create_file(".tddium.test", branch_params.merge(:api_key => DEFAULT_API_KEY).to_json)
  end

  def stub_git_push(tddium)
    tddium.stub(:`).with(/^git push/)
  end

  def stub_sleep(tddium)
    tddium.stub(:sleep).with(Tddium::Default::SLEEP_TIME_BETWEEN_POLLS)
  end

  let(:tddium) { Tddium.new }

  shared_examples_for "git repo has not been initialized" do
    context "git repo has not been initialized" do
      before do
        FileUtils.rm_rf(".git")
      end

      it "should return git is uninitialized" do
        tddium.should_receive(:say).with("git repo must be initialized. Try 'git init'.")
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

  shared_examples_for "sending the api key" do
    it "should include the api key in the headers" do
      run(tddium)
      FakeWeb.last_request[Tddium::Api::KEY_HEADER].should == DEFAULT_API_KEY
    end
  end

  describe "#suite" do
    before do
      stub_defaults
      stub_config_file
      stub_ruby_version(tddium)
      stub_http_response(:post, Tddium::Api::Path::SUITES)
      tddium.stub(:ask).and_return("")
      create_file("~/.ssh/id_rsa.pub", "ssh-rsa blah")
    end

    it "should ask the user for their ssh key" do
      tddium.should_receive(:ask).with(Tddium::Text::Prompt::SSH_KEY)
      run_suite(tddium)
    end

    it "should ask for a test file pattern" do
      tddium.should_receive(:ask).with(Tddium::Text::Prompt::TEST_PATTERN)
      run_suite(tddium)
    end

    context "using defaults" do
      it "should POST the default values to the API" do
        run_suite(tddium)
        parse_request_params["suite"].should include("ssh_key" => "ssh-rsa blah", "test_pattern" => "**/*_spec.rb")
      end
    end

    context "passing arguments" do
      let(:ssh_key_file) { "~/.ssh/blah.txt" }
      let(:cli_args) { { :ssh_key => ssh_key_file, :test_pattern => "**/*_test.rb", :environment => "test" } }
      before do
        create_file(ssh_key_file, "ssh-rsa 1234")
      end

      it "should POST the passed in values to the API" do
        run_suite(tddium, cli_args)
        parse_request_params["suite"].should include("ssh_key" => "ssh-rsa 1234", "test_pattern" => "**/*_test.rb")
      end

    end

    context "interactive mode" do
      before do
        ssh_key_file = "~/.ssh/foo.txt"
        tddium.stub(:ask).with(Tddium::Text::Prompt::SSH_KEY).and_return(ssh_key_file)
        tddium.stub(:ask).with(Tddium::Text::Prompt::TEST_PATTERN).and_return("**/*_selenium.rb")
        create_file(ssh_key_file, "ssh-rsa 65431")
      end

      it "should POST the passed in values to the API" do
        run_suite(tddium)
        parse_request_params["suite"].should include("ssh_key" => "ssh-rsa 65431", "test_pattern" => "**/*_selenium.rb")
      end
    end

    it_should_behave_like "sending the api key"
    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium.test file is missing or corrupt"
    
    context "suite has not yet been registered" do
      it "should ask for a suite name" do
        stub_default_suite_name(tddium)
        stub_config_file
        tddium.should_receive(:ask).with(suite_name_prompt)
        run_suite(tddium)
      end

      it "should send a 'POST' request to '#{Tddium::Api::Path::SUITES}'" do
        run_suite(tddium)
        FakeWeb.last_request.method.should == "POST"
        FakeWeb.last_request.path.should =~ /\/#{Tddium::Api::Path::SUITES}$/
      end

      it "should post the current ruby version to the API" do
        stub_ruby_version(tddium, "1.9.2")
        run_suite(tddium)
        parse_request_params["suite"].should include("ruby_version" => "1.9.2")
      end

      context "using defaults" do
        before do
          stub_default_suite_name(tddium)
        end

        it "should POST the default values to the API" do
          run_suite(tddium)
          parse_request_params["suite"].should include("suite_name" => default_suite_name)
        end
      end

      context "passing arguments" do
        let(:cli_args) { { :name => "my_suite_name", :environment => "test" } }

        it "should POST the passed in values to the API" do
          run_suite(tddium, cli_args)
          parse_request_params["suite"].should include("suite_name" => "my_suite_name")
        end
      end

      context "interactive mode" do
        before do
          tddium.stub(:ask).with(suite_name_prompt).and_return("foobar")
          stub_default_suite_name(tddium)
        end

        it "should POST the passed values to the API" do
          run_suite(tddium)
          parse_request_params["suite"].should include("suite_name" => "foobar")
        end
      end

      context "API response successful" do
        before do
          stub_http_response(:post, Tddium::Api::Path::SUITES, :response => fixture_path("post_suites_201.json"))
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
            JSON.parse(tddium_file)["branches"]["oaktree"].should == 19 # From response
          end
        end
      end

      context "API response successful but JSON status not 0" do
        before do
          stub_http_response(:post, Tddium::Api::Path::SUITES, :response => fixture_path("post_suites_201_json_status_1.json"))
        end

        it "should do show the explaination" do
          tddium.should_receive(:say).with("An error occured: {:suite_name=>[\"has already been taken\"]}")
          run_suite(tddium)
        end
      end

      context "API response unsuccessful" do
        before do
          stub_http_response(:post, Tddium::Api::Path::SUITES, :status => ["501", "Internal Server Error"])
        end

        it "should show that there was an error" do
          tddium.should_receive(:say).with(/^An error occured: /)
          run_suite(tddium)
        end

        context "API status code != 0" do
          before do
            stub_http_response(:post, Tddium::Api::Path::SUITES, :response => fixture_path("post_suites_409.json"))
          end

          it "should show the error message" do
            tddium.should_receive(:say).with(/Conflict \{\:suite_name\=\>\[\"has already been taken\"\]\}$/)
            run_suite(tddium)
          end
        end

        context "501 Error" do
          before do
            stub_http_response(:post, Tddium::Api::Path::SUITES, :status => ["501", "Internal Server Error"])
          end

          it "should show the HTTP error message" do
            tddium.should_receive(:say).with(/Internal Server Error$/)
            run_suite(tddium)
          end
        end
      end
    end
    context "suite has already been registered" do
      before do
        stub_config_file(false)
        stub_http_response(:put, "#{Tddium::Api::Path::SUITE}/#{DEFAULT_SUITE_ID}")
      end

      it "should send a 'PUT' request to '#{Tddium::Api::Path::SUITE}/#{DEFAULT_SUITE_ID}'" do
        run_suite(tddium)
        FakeWeb.last_request.method.should == "PUT"
        FakeWeb.last_request.path.should =~ /\/#{Tddium::Api::Path::SUITE}\/#{DEFAULT_SUITE_ID}$/
      end
    end
  end

  describe "#spec" do
    before do
      stub_defaults
      stub_config_file(false)
      stub_git_push(tddium)
      stub_http_response(:get, "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}")
    end

    it_should_behave_like "git repo has not been initialized"
    it_should_behave_like ".tddium.test file is missing or corrupt"

    it "should push the latest code to tddium" do
      tddium.should_receive(:`).with("git push #{Tddium::Git::REMOTE_NAME} #{DEFAULT_BRANCH_NAME}")
      run_spec(tddium)
    end

    it "should send a 'GET' request to '#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}'" do
      run_spec(tddium)
      FakeWeb.last_request.method.should == "GET"
      FakeWeb.last_request.path.should =~ /#{Tddium::Api::Path::SUITES}\/#{DEFAULT_SUITE_ID}$/
    end

    it_should_behave_like "sending the api key"

    context "'GET #{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}' is successful" do
      before do
        stub_http_response(:get, "#{Tddium::Api::Path::SUITES}/#{DEFAULT_SUITE_ID}", :response => fixture_path("get_suites_200.json"))
        stub_http_response(:post, Tddium::Api::Path::SESSIONS)
        create_file("spec/mouse_spec.rb")
        create_file("spec/cat_spec.rb")
        create_file("spec/dog_spec.rb")
      end

      it "should send a 'POST' request to '#{Tddium::Api::Path::SESSIONS}'" do
        run_spec(tddium)
        FakeWeb.last_request.method.should == "POST"
        FakeWeb.last_request.path.should =~ /#{Tddium::Api::Path::SESSIONS}$/
      end

      it_should_behave_like "sending the api key"

      context "'POST #{Tddium::Api::Path::SESSIONS}' is successful" do
        let(:session_id) {7} # from the fixture 'post_sessions_201.json'
        before do
          stub_http_response(:post, "#{Tddium::Api::Path::SESSIONS}", :response => fixture_path("post_sessions_201.json"))
          stub_http_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}")
        end

        it "should send a 'POST' request to '#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}'" do
          run_spec(tddium)
          FakeWeb.last_request.method.should == "POST"
          FakeWeb.last_request.path.should =~ /#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}$/
        end

        it_should_behave_like "sending the api key"

        it "should POST the names of the file names extracted from the suite's test_pattern" do
          run_spec(tddium)
          request_params = parse_request_params
          request_params.should include({"suite_id" => DEFAULT_SUITE_ID})
          request_params["tests"][0]["test_name"].should =~ /spec\/cat_spec.rb$/
          request_params["tests"][1]["test_name"].should =~ /spec\/dog_spec.rb$/
          request_params["tests"][2]["test_name"].should =~ /spec\/mouse_spec.rb$/
          request_params["tests"].size.should == 3
        end

        context "'POST #{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}' is successful" do
          before do
            stub_http_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::REGISTER_TEST_EXECUTIONS}", :response => fixture_path("post_register_test_executions_200.json"))
            stub_http_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::START_TEST_EXECUTIONS}")
          end

          it "should send a 'POST' request to '#{Tddium::Api::Path::START_TEST_EXECUTIONS}'" do
            run_spec(tddium)
            FakeWeb.last_request.method.should == "POST"
            FakeWeb.last_request.path.should =~ /#{Tddium::Api::Path::START_TEST_EXECUTIONS}$/
          end

          it_should_behave_like "sending the api key"

          context "'POST #{Tddium::Api::Path::START_TEST_EXECUTIONS}' is successful" do
            before do
              stub_http_response(:post, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::START_TEST_EXECUTIONS}", :response => fixture_path("post_start_test_executions_200.json"))
              stub_http_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::TEST_EXECUTIONS}")
            end

            it "should tell the user to '#{Tddium::Text::Process::TERMINATE_INSTRUCTION}'" do
              tddium.should_receive(:say).with(Tddium::Text::Process::TERMINATE_INSTRUCTION)
              run_spec(tddium)
            end

            it "should send a 'GET' request to '#{Tddium::Api::Path::TEST_EXECUTIONS}'" do
              run_spec(tddium)
              FakeWeb.last_request.method.should == "GET"
              FakeWeb.last_request.path.should =~ /#{Tddium::Api::Path::TEST_EXECUTIONS}$/
            end

            it_should_behave_like "sending the api key"

            shared_examples_for("test output summary") do
              it "should display a link to the report" do
                tddium.should_receive(:say).with("You can check out the test report details at http://api.tddium.com/1/sessions/7/test_executions/report")
                run_spec(tddium)
              end

              it "should display the time taken" do
                tddium.should_receive(:say).with(/^Finished in [\d\.]+ seconds$/)
                run_spec(tddium)
              end
            end

            context "user presses 'Ctrl-C' during the process" do
              before do
                stub_http_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::TEST_EXECUTIONS}", :response => fixture_path("get_test_executions_200.json"))
                Signal.stub(:trap).with(:INT).and_yield
                stub_sleep(tddium)
              end

              it "should display '#{Tddium::Text::Process::INTERRUPT}'" do
                tddium.should_receive(:say).with(Tddium::Text::Process::INTERRUPT)
                run_spec(tddium)
              end

              it "should display a summary of all the tests" do
                tddium.should_receive(:say).with("3 examples, 1 failures, 0 errors, 1 pending")
                run_spec(tddium)
              end

              it_should_behave_like("test output summary")
            end

            context "'GET #{Tddium::Api::Path::TEST_EXECUTIONS}' is successful" do
              before do
                stub_http_response(:get, "#{Tddium::Api::Path::SESSIONS}/#{session_id}/#{Tddium::Api::Path::TEST_EXECUTIONS}", [{:response => fixture_path("get_test_executions_200.json")}, {:response => fixture_path("get_test_executions_200_all_finished.json")}])
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
          end
        end
      end
    end
  end
end
