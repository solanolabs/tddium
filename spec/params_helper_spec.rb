# Copyright (c) 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/cli/params_helper'
require 'highline/import'
require 'tddium/constant'
require 'json'

describe 'Params' do
  include TddiumConstant
  extend ParamsHelper

  let(:params) { {host: 'localhost', port: 3000, insecure: false, proto: 'http'} }

  it 'should create file to store params' do
    self.class.write_params params
    Dir.glob(self.class::Default::PARAMS_PATH).length.should eq(1)
  end

  it 'file should have correct content' do
    params_json = JSON.parse(params.to_json)
    self.class.load_params.should eq(params_json)
  end
end
