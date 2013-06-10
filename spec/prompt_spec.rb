# Copyright (c) 2013 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/cli'

describe Tddium::TddiumCli do
  let(:api_config) { mock(Tddium::ApiConfig, :get_branch => nil) }
  let(:tddium_api) { mock(Tddium::TddiumAPI) }
  let(:tddium_client) { mock(TddiumClient::Client, :environment => :production) }

  def stub_tddium_api
    tddium_api.stub(:user_logged_in?).and_return(true)
    Tddium::TddiumAPI.stub(:new).and_return(tddium_api)
  end

  def stub_tddium_client
    tddium_client.stub(:caller_version=)
    tddium_client.stub(:environment=)
    tddium_client.stub(:call_api)
    TddiumClient::Client.stub(:new).and_return(tddium_client)
  end

  def should_have_called_prompt
    @prompt_calls.should eq(1)
  end

  def should_not_have_called_prompt
    @prompt_calls.should eq(0)
  end

  before do
    stub_tddium_client
    stub_tddium_api
    subject.stub(:say)  # Be quieter
  end

  describe "#prompt_suite_params" do
    before do
      # Make it public so we can test it.
      Tddium::TddiumCli.send(:public, :prompt_suite_params)
    end

    describe "account logic" do
      before do
        @prompt_calls = 0
        subject.stub(:prompt) do |text, current_value, default_value, dont_prompt|
          @prompt_calls += 1 if /account/i.match(text)
          default_value
        end
      end

      def stub_accounts(n)
        accounts = (1..n).map {|x|
          {"account_id" => x, "account" => "handle-#{x}"}
        }
        subject.stub(:user_details).and_return({"all_accounts" => accounts})
      end

      it "should not use an account_id for an existing suite" do
        stub_accounts(1)
        params = {}
        subject.prompt_suite_params({}, params, {"account_id" => 123})
        params.should_not include(:account_id)
        should_not_have_called_prompt
      end

      it "should fail with a bad account option" do
        stub_accounts(1)
        expect {
          subject.prompt_suite_params({:account => "abc"}, {})
        }.to raise_error(SystemExit, "You aren't a member of account abc.")
        should_not_have_called_prompt
      end

      it "should use an account from an option" do
        stub_accounts(3)
        params = {}
        subject.prompt_suite_params({:account => "handle-2"}, params)
        params[:account_id].should eq("2")
        should_not_have_called_prompt
      end

      it "should default to the only account" do
        stub_accounts(1)
        params = {}
        subject.prompt_suite_params({}, params)
        params[:account_id].should eq("1")
        should_not_have_called_prompt
      end

      it "should default to the same repo as an existing suite" do
        stub_accounts(3)
        tddium_api.stub(:get_suites).and_return([
          {"account" => "handle-2"},
        ])
        params = {}
        subject.prompt_suite_params({}, params)
        params[:account_id].should eq("2")
        should_have_called_prompt
      end

      it "should fail to default if multiple suites with the same repo" do
        stub_accounts(3)
        tddium_api.stub(:get_suites).and_return([
          {"account" => "handle-2"},
          {"account" => "handle-3"},
        ])
        expect {
          subject.prompt_suite_params({}, {})
        }.to raise_error(SystemExit, "You must specify an account.")
        should_have_called_prompt
      end
    end
  end
end
