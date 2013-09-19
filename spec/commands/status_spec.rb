require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/status'

describe Tddium::TddiumCli do
  include_context "tddium_api_stubs"

  describe "#status" do
    let(:suite_id) { 1 }

    it "should display current status with no suites or sessions" do
      tddium_api.should_receive(:get_suites).and_return([])
      tddium_api.should_receive(:get_sessions).exactly(2).times.and_return([])
      tddium_api.stub(:current_suite_id).and_return(suite_id)
      subject.status
    end
  end 
end
