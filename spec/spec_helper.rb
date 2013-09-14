# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

#require 'simplecov'
#SimpleCov.start

require 'tddium'

require 'rspec'
require 'fakefs/spec_helpers'

require 'ostruct'
require 'stringio'
require 'fileutils'

class Open3SpecHelper
  def self.stubOpen2e(data, ok, block)
    stdin = StringIO.new
    output = StringIO.new(data)
    status = (ok && 0) || 1
    value = OpenStruct.new(:exitstatus => status, :to_i => status)
    wait = OpenStruct.new(:value => value)
    block.call(stdin, output, wait)
  end
end

def env_save
  return ENV.to_hash.dup
end

def env_restore(env)
  env.each_pair do |k, v|
    ENV[k] = v
  end
end

shared_context "tddium_api_stubs" do
  let(:api_config) { mock(Tddium::ApiConfig, :get_branch => nil) }
  let(:tddium_api) { mock(Tddium::TddiumAPI) }
  let(:tddium_client) { mock(TddiumClient::InternalClient) }

  def stub_tddium_api
    tddium_api.stub(:user_logged_in?).and_return(true)
    Tddium::TddiumAPI.stub(:new).and_return(tddium_api)
  end

  def stub_tddium_client
    tddium_client.stub(:caller_version=)
    tddium_client.stub(:call_api)
    TddiumClient::InternalClient.stub(:new).and_return(tddium_client)
  end

  before do
    stub_tddium_client
    stub_tddium_api
  end
end

