# Copyright (c) 2014 Solano Labs All Rights Reserved

require 'tddium/constant'
require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/keys'

describe Tddium::TddiumCli do
  include_context "tddium_api_stubs"

  describe '.keys:add' do
    it 'calls correct method' do
      Tddium::Ssh.should_receive(:validate_keys).with('some_key', '/home/.ssh/id_rsa.pub', tddium_api)
      tddium_api.should_receive(:set_keys).and_return({'gitserver' => 'api.tddium.com'})

      subject.send('keys:add', 'some_key', '/home/.ssh/id_rsa.pub')
    end
  end

  describe '.keys:gen' do
    it 'calls corrent method' do
      Tddium::Ssh.should_receive(:validate_keys).with(
                                                      'some_key',
                                                      Tddium::TddiumCli::Default::SSH_OUTPUT_DIR,
                                                      tddium_api,
                                                      true
                                                      )
      tddium_api.should_receive(:set_keys).and_return({'gitserver' => 'api.tddium.com'})

      subject.send('keys:gen', 'some_key')
    end
  end
end
