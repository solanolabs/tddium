# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium_client'
require 'tddium/cli/api'
require 'tddium/cli/config'

describe Tddium::TddiumAPI do
  let(:api_config) { mock(Tddium::ApiConfig, :get_branch => nil) }
  let(:tddium_client) { mock(TddiumClient::Client) }
  let(:subject) { Tddium::TddiumAPI.new(api_config, tddium_client) }

  shared_examples_for "retrieving the branch info" do
    before do
      Tddium::Git.stub(:git_current_branch).and_return("master")
      api_config.stub(:get_branch).with("master", key).and_return(key)
    end

    it "should not try to read the branch from git more than once when called multiple times" do
      Tddium::Git.should_receive(:git_current_branch).once
      2.times do
        subject.send(method)
      end
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
end
