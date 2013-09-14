require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/spec'

describe Tddium::TddiumCli do
  describe "#rerun" do
    include_context "tddium_api_stubs"

    let(:session_id) { 123 }
    let(:query_session_result) {
      {'session'=> {'tests' => [{'status'=>'failed', 'test_name'=>'foo.rb'}]}}
    }

    it "should produce a command line from an old session's results" do
      tddium_api.should_receive(:query_session).with(session_id).and_return(query_session_result)
      Kernel.should_receive(:exec).with(/tddium run foo.rb/)

      subject.rerun(session_id)
    end
  end
end
