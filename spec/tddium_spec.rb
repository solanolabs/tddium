require 'spec_helper'

describe Tddium do
  include FakeFS::SpecHelpers

  SSH_KEY_PROMPT = "Enter your ssh key or press 'Return'. Using ~/.ssh/id_rsa.pub by default:"
  TEST_PATTERN_PROMPT = "Enter a test pattern or press 'Return'. Using **/*_spec.rb by default:"
  DEFAULT_APP_NAME = "tddelicious"
  DEFAULT_BRANCH_NAME = "test"
  TDDIUM_API_HOST = "http://api.tddium.com/1/suites"

  def run_suite(tddium)
    tddium.suite
  end

  def suite_name_prompt(default = default_suite_name)
    "Enter a suite name or press 'Return'. Using '#{default}' by default:"
  end

  def default_suite_name
    File.join(DEFAULT_APP_NAME, DEFAULT_BRANCH_NAME)
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

  def parse_request_params(raw_params = FakeWeb.last_request.body)
    Rack::Utils.parse_nested_query(raw_params)["suite"]
  end

  def create_file(path = "~/.ssh/id_rsa.pub", content = "ssh-rsa blah")
    FileUtils.mkdir_p(File.dirname(File.expand_path(path)))
    File.open(path, 'w') do |f|
      f.write(content)
    end
  end

  def stub_http_response(options = {})
    fake_web_options = {:body => options[:body], :status => options[:status]}
    if options[:response]
      FakeFS.deactivate!
      response = File.open(options[:response]) { |f| f.read }
      FakeFS.activate!
      fake_web_options.merge!(:response => response)
    end
    FakeWeb.register_uri(:post, "http://api.tddium.com/1/suites", fake_web_options)
  end

  let(:tddium) { Tddium.new }
  describe "#suite" do
    before do
      FakeWeb.clean_registry
      tddium.stub(:ask).and_return("")
      tddium.stub(:say)
      stub_http_response
      stub_ruby_version(tddium)
      stub_git_branch(tddium)
      create_file
      create_file(".git/something", "something")
    end

    it "should ask the user for their ssh key" do
      tddium.should_receive(:ask).with(SSH_KEY_PROMPT)
      run_suite(tddium)
    end

    it "should ask for a suite name" do
      stub_default_suite_name(tddium)
      tddium.should_receive(:ask).with(suite_name_prompt)
      run_suite(tddium)
    end

    it "should ask for a test file pattern" do
      tddium.should_receive(:ask).with(TEST_PATTERN_PROMPT)
      run_suite(tddium)
    end

    it "should send a 'POST' request to the tddium API" do
      run_suite(tddium)
      FakeWeb.last_request.method.should == "POST"
      FakeWeb.last_request.path.should == "/1/suites"
    end

    it "should post the current ruby version to the API" do
      stub_ruby_version(tddium, "1.9.2")
      run_suite(tddium)
      request_params = parse_request_params
      request_params.should include("ruby_version" => "1.9.2")
    end

    context "git repo has not been initialized" do
      before do
        FileUtils.rm_rf(".git")
      end

      it "should return git is uninitialized" do
        tddium.should_receive(:say).with("git repo must be initialized. Try 'git init'.")
        run_suite(tddium)
      end
    end
    
    context "using defaults" do
      before do
        stub_default_suite_name(tddium)
      end

      it "should POST the default values to the API" do
        run_suite(tddium)
        request_params = parse_request_params
        request_params.should include("ssh_key" => "ssh-rsa blah", "suite_name" => default_suite_name,
                                      "test_pattern" => "**/*_spec.rb")
      end

    end

    context "passing arguments" do
      before do
        ssh_key_file = "~/.ssh/blah.txt"
        tddium.stub(:options).and_return(
          :ssh_key => ssh_key_file,
          :name => "my_suite_name",
          :test_pattern => "**/*_test.rb"
        )
        create_file(ssh_key_file, "ssh-rsa 1234")
      end

      it "should POST the passed in values to the API" do
        run_suite(tddium)
        request_params = parse_request_params
        request_params.should include("ssh_key" => "ssh-rsa 1234", "suite_name" => "my_suite_name",
                                      "test_pattern" => "**/*_test.rb")
      end

    end

    context "interactive mode" do
      before do
        ssh_key_file = "~/.ssh/foo.txt"
        tddium.stub(:ask).with(SSH_KEY_PROMPT).and_return(ssh_key_file)
        tddium.stub(:ask).with(TEST_PATTERN_PROMPT).and_return("**/*_selenium.rb")
        tddium.stub(:ask).with(suite_name_prompt).and_return("foobar")
        stub_default_suite_name(tddium)
        create_file(ssh_key_file, "ssh-rsa 65431")
      end

      it "should POST the passed in values to the API" do
        run_suite(tddium)
        request_params = parse_request_params
        request_params.should include("ssh_key" => "ssh-rsa 65431", "suite_name" => "foobar",
                                      "test_pattern" => "**/*_selenium.rb")
      end
    end

    context "API response successful" do
      before do
        stub_http_response(:response => fixture_path("post_suites_201.json"))
        tddium.stub(:`).with(/^git remote/)
        tddium.stub(:`).with(/^git push/)
      end

      it "should remove any existing remotes named 'tddium'" do
        tddium.should_receive(:`).with("git remote rm tddium")
        run_suite(tddium)
      end

      it "should add a new remote called 'tddium'" do
        stub_default_suite_name(tddium)
        tddium.should_receive(:`).with("git remote add tddium ssh://git@api.tddium.com/home/git/repo/#{default_suite_name}")
        run_suite(tddium)
      end

      context "in the branch 'oaktree'" do
        before do
          tddium.stub(:current_git_branch).and_return("oaktree")
        end

        it "should push the current git branch to tddium:master" do
          tddium.should_receive(:`).with("git push tddium oaktree:master")
          run_suite(tddium)
        end

        it "should create '.tddium' and write the suite_id and branch name" do
          run_suite(tddium)
          tddium_file = File.open(".tddium") { |file| file.read }
          JSON.parse(tddium_file)["oaktree"].should == 19 # From response
        end
      end
    end

    context "API response successful but JSON status not 0" do
      before do
        stub_http_response(:response => fixture_path("post_suites_201_json_status_1.json"))
      end

      it "should do show the explaination" do
        tddium.should_receive(:say).with("An error occured: {:suite_name=>[\"has already been taken\"]}")
        run_suite(tddium)
      end
    end

    context "API response unsuccessful" do
      before do
        stub_http_response(:status => ["501", "Internal Server Error"])
      end

      it "should show that there was an error" do
        tddium.should_receive(:say).with(/^An error occured: /)
        run_suite(tddium)
      end

      context "API status code != 0" do
        before do
          stub_http_response(:response => fixture_path("post_suites_409.json"))
        end

        it "should show the error message" do
          tddium.should_receive(:say).with(/Conflict \{\:suite_name\=\>\[\"has already been taken\"\]\}$/)
          run_suite(tddium)
        end
      end

      context "501 Error" do
        before do
          stub_http_response(:status => ["501", "Internal Server Error"])
        end

        it "should show the HTTP error message" do
          tddium.should_receive(:say).with(/Internal Server Error$/)
          run_suite(tddium)
        end
      end
    end
  end
end
