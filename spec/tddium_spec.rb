require 'spec_helper'

describe Tddium do
  include FakeFS::SpecHelpers

  SSH_KEY_PROMPT = "Enter your ssh key or press 'Return'. Using ~/.ssh/id_rsa.pub by default:"
  TEST_PATTERN_PROMPT = "Enter a test pattern or press 'Return'. Using **/*_spec.rb by default:"
  DEFAULT_SUITE_NAME = "tddelicious"
  TDDIUM_API_HOST = "http://api.tddium.com/1/suites"

  def run_suite(tddium)
    tddium.suite
  end

  def suite_name_prompt(default = DEFAULT_SUITE_NAME)
    "Enter a suite name or press 'Return'. Using '#{default}' by default:"
  end

  def stub_default_suite_name(default = DEFAULT_SUITE_NAME)
    Dir.stub(:pwd).and_return(default)
  end

  def parse_request_params(raw_params = FakeWeb.last_request.body)
    Rack::Utils.parse_nested_query(raw_params)["suite"]
  end

  def create_public_key_file(path = "~/.ssh/id_rsa.pub", content = "ssh-rsa blah")
    FileUtils.mkdir_p(File.dirname(File.expand_path(path)))
    File.open(path, 'w') do |f|
      f.write(content)
    end
  end

  def stub_http_response(body = nil)
    FakeWeb.register_uri(:post, "http://api.tddium.com/1/suites", :body => body)
  end

  let(:tddium) { Tddium.new }
  describe "#suite" do
    before do
      tddium.stub(:ask).and_return("")
      stub_http_response
      create_public_key_file
    end

    it "should ask the user for their ssh key" do
      tddium.should_receive(:ask).with(SSH_KEY_PROMPT)
      run_suite(tddium)
    end

    it "should ask for a suite name" do
      stub_default_suite_name
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
      tddium.stub(:`).with("ruby -v").and_return("ruby 1.9.2 (2010-08-16 patchlevel 302) [i686-darwin10.5.0]")
      run_suite(tddium)
      request_params = parse_request_params
      request_params.should include("ruby_version" => "1.9.2")
    end
    
    context "using defaults" do
      before do
        stub_default_suite_name
      end

      it "should POST the default values to the API" do
        run_suite(tddium)
        request_params = parse_request_params
        request_params.should include("ssh_key" => "ssh-rsa blah", "suite_name" => DEFAULT_SUITE_NAME,
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
        create_public_key_file(ssh_key_file, "ssh-rsa 1234")
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
        stub_default_suite_name
        create_public_key_file(ssh_key_file, "ssh-rsa 65431")
      end

      it "should POST the passed in values to the API" do
        run_suite(tddium)
        request_params = parse_request_params
        request_params.should include("ssh_key" => "ssh-rsa 65431", "suite_name" => "foobar",
                                      "test_pattern" => "**/*_selenium.rb")
      end

    end

  end
end
