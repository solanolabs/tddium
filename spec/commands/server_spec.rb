# Copyright (c) 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/server'

describe Tddium::TddiumCli do
  include TddiumConstant

  describe '#server' do
    let(:options){ {host: 'localhost', port: 3000, proto: 'http', insecure: true} }

    it 'stores options and returns successfully message' do
      subject.stub('server:set').with(options).and_return(self.class::Text::Process::OPTIONS_SAVED)
    end

    it 'raises an error if file with options does not exists' do
      `rm ~/.tddium`
      expect{ subject.server }.to raise_error(SystemExit, self.class::Text::Process::NOT_SAVED_OPTIONS)
    end

    it 'prints stored options' do
      subject.send('server:set')
      subject.class.should_receive(:display)
      subject.server
    end
  end
end