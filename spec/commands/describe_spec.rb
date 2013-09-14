require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/spec'

describe Tddium::TddiumCli do
  describe "#describe" do
    include_context "tddium_api_stubs"

    let(:session_id) { 123 }
    let(:query_session_result) {
      {'session'=> {'tests' => [{'status'=>'failed', 'test_name'=>'foo.rb'}]}}
    }
  
    before do
      tddium_api.should_receive(:query_session).with(session_id).and_return(query_session_result)
    end

    it "should table print the failures" do
      subject.should_receive(:print_table)
      subject.describe(session_id)
    end

    it "should print only names if indicated" do
      subject.stub(:options) { { :names => true } }
      subject.should_receive(:say).with("foo.rb")
      subject.describe(session_id)
    end
  end
end
