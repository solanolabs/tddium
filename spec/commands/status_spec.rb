require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/status'

describe Tddium::TddiumCli do
  include_context "tddium_api_stubs"

  describe "#status" do
    let(:suite_id) { 1 }

    it "should display current status with no suites or sessions" do
      tddium_api.should_not_receive(:get_suites)
      subject.should_receive(:suite_for_current_branch?).and_return(false)
      tddium_api.should_receive(:get_sessions).once.and_return([])
      subject.status
    end

    context "with suite" do
      before do
        subject.stub(:suite_for_current_branch?) { true }
        tddium_api.stub(:current_suite_id) { suite_id }
        tddium_api.stub(:current_branch) { "branch" }
      end

      it "should display current status with no sessions" do
        tddium_api.should_not_receive(:get_suites)
        tddium_api.should_receive(:get_sessions).exactly(2).times.and_return([])
        subject.status
      end

      it "should display current status as JSON with no sessions" do
        tddium_api.should_not_receive(:get_suites)
        tddium_api.should_receive(:get_sessions).exactly(2).times.and_return([])
        subject.stub(:options) { {:json => true } }
        subject.status
      end

      it "should display current status as valid JSON" do
        tddium_api.should_not_receive(:get_suites)
        tddium_api.should_receive(:get_sessions).exactly(2).times.and_return([])
        subject.should_receive(:puts).with(/running|history/i)
        subject.should_not_receive(:puts).with(/Re-run failures from a session with/i)
        subject.stub(:options) { {:json => true } }
        subject.status
      end
    end
  end 
end
