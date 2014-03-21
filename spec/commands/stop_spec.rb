require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/stop'

describe Tddium::TddiumCli do
  describe "#stop" do
    include_context "tddium_api_stubs"

    let(:ls_id) { 123 }
    let(:stop_session_result) {
      {'status'=>'0', 'notice'=>"Stopped session #{ls_id}"}
    }

    it "should produce a command line from an old session's results" do
      tddium_api.should_receive(:stop_session).with(ls_id).and_return(stop_session_result)
      subject.should_receive(:say).with("Stoping session #{ls_id} ...")
      subject.should_receive(:say).with(stop_session_result['notice'])

      subject.stop(ls_id)
    end
  end
end
