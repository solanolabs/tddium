# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium_client'
require 'tddium/cli/api'
require 'tddium/cli/config'

describe Tddium::TddiumAPI do
  let(:scm) { Tddium::SCM.configure }
  let(:api_config) { double(Tddium::ApiConfig, :get_branch => nil) }
  let(:tddium_client) { double(TddiumClient::Client) }
  let(:subject) { Tddium::TddiumAPI.new(api_config, tddium_client, scm) }

  shared_examples_for "retrieving the branch info" do
    before do
      scm.stub(:current_branch).and_return("master")
      api_config.stub(:get_branch).with("master", key).and_return(key)
    end

    it "should return the branch info" do
      subject.send(method).should == key
    end
  end

  describe "#current_suite_id" do
    it_should_behave_like "retrieving the branch info" do
      let(:method) { :current_suite_id }
      let(:key) { "id" }
    end
  end

  describe "#current_suite_options" do
    it_should_behave_like "retrieving the branch info" do
      let(:method) { :current_suite_options }
      let(:key) { "options" }
    end
  end

  describe "#create_session(suite_id, params = {})" do
    before do
      api_config.stub(:get_api_key)
      tddium_client.stub(:call_api).and_return({"session" => "session_json"})
    end

    it "should post to /sessions" do
      tddium_client.should_receive(:call_api).with(:post, "sessions", {:suite_id => 1, :commits => ["foo"]}, nil)
      subject.create_session(1, :commits => ["foo"]).should == "session_json"
    end
  end

  describe "#user_logged_in?" do
    before do
      api_config.stub(:get_api_key)
      subject.stub(:say)
    end

    let(:global_api_key) { "global_api_key" }
    let(:repo_api_key) { "repo_api_key" }

    context "where the global api key is set" do
      before do
        api_config.stub(:get_api_key).with(:global => true).and_return(global_api_key)
      end

      context "but the repos api key is missing" do
        before do
          api_config.stub(:get_api_key).with(:repo => true).and_return(nil)
        end

        it "should return the global api key" do
          subject.user_logged_in?(false, false).should == global_api_key
        end
      end

      context "and the repos api key is the same as the global api key" do
        before do
          api_config.stub(:get_api_key).with(:repo => true).and_return(global_api_key)
        end

        it "should return the repo api key" do
          subject.user_logged_in?(false, false).should == global_api_key
        end
      end

      context "but the repos api key is different from the global api key" do
        before do
          api_config.stub(:get_api_key).with(:repo => true).and_return(repo_api_key)
        end

        it "should return nil" do
          subject.should_not_receive(:say)
          subject.user_logged_in?(false, false).should be_nil
        end

        context "with args false, true" do
          it "should print a message saying the users credentials are invalid" do
            subject.should_receive(:say).with(
              "Your .tddium file has an invalid API key.\nRun `tddium logout` and `tddium login`, and then try again."
            )
            subject.user_logged_in?(false, true)
          end
        end
      end
    end
  end
end
