# Copyright (c) 2014 Solano Labs All Rights Reserved

# delete tddium-server file before require tddium/cli/tddium.rb
# it will use stored options, not default (if server-file already exist)
require 'tddium/constant'

def remove_server_file
  `rm #{TddiumConstant::Default::PARAMS_PATH}`
end

remove_server_file

require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/server'

describe Tddium::TddiumCli do
  include TddiumConstant
  extend ParamsHelper

  describe '#server:set' do
    let(:options){ {'host' => 'localhost', 'port' => 3000, 'proto' => 'http', 'insecure' => true} }
    let(:default_options){ {'host' => 'ci.solanolabs.com', 'proto' => 'https', 'insecure' => false} }

    it 'PARAMS_PATH constant presence' do
      expect(self.class::Default::PARAMS_PATH).not_to be_empty
    end

    it 'has default options' do
      subject
        .class
        .should_receive(:write_params)
        .with(default_options)
      subject.send 'server:set'
    end

    it 'calls write_params method' do
      subject.options = options
      subject
        .class
        .should_receive(:write_params)
        .with(subject.options)
        .and_return(self.class::Text::Process::OPTIONS_SAVED)
      subject.send 'server:set'
    end

    it 'creates server file' do
      #server file should not be exists
      remove_server_file
      Dir.glob(self.class::Default::PARAMS_PATH).length.should eq(0)

      expect{
        subject.send('server:set')
      }.to change{
        Dir.glob(self.class::Default::PARAMS_PATH).length
      }.from(0)
       .to(1)
    end

    it 'writes correct content' do
      subject.options = options
      subject.send 'server:set'
      content = JSON.parse File.read(self.class::Default::PARAMS_PATH)
      content.should eq(options)
    end
  end

  describe '#server' do
    let(:default_options){ {'host' => 'ci.solanolabs.com', 'proto' => 'https', 'insecure' => false} }

    it 'calls display method' do
      subject.class.should_receive(:display)
      subject.send :server
    end

    it 'returns corrent content' do
      remove_server_file
      subject.send('server:set')
      subject
        .class
        .should_receive(:display)
        .and_return(default_options)
      subject.send :server
    end

    it 'raises an error if file with options does not exists' do
      remove_server_file
      expect{ subject.server }.to raise_error(SystemExit, self.class::Text::Process::NOT_SAVED_OPTIONS)
    end

    it 'returns empty hash, than stored options' do
      Tddium::TddiumCli
        .should_receive(:load_params)
        .and_return({})
      Tddium::TddiumCli.load_params
    end
  end
end