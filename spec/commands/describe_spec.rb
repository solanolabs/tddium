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
    let(:suite_id) { 1 }
    let(:git_commit) { 'abcdef' }
    let(:get_sessions_result) {
      [{'id' => session_id, 'status' => 'passed', 'commit' => git_commit, 'start_time' => Time.now.utc.to_s, 'duration' => 1}]
    }

    it "should table print the failures" do
      tddium_api.should_receive(:query_session).with(session_id).and_return(query_session_result)
      subject.should_receive(:print_table)
      subject.describe(session_id)
    end

    it "should print only names if indicated" do
      tddium_api.should_receive(:query_session).with(session_id).and_return(query_session_result)
      subject.stub(:options) { { :names => true } }
      subject.should_receive(:say).with("foo.rb")
      subject.describe(session_id)
    end

    it "should exit with failure when no recent sessions exist on current branch" do
      tddium_api.stub(:current_suite_id) { suite_id }
      subject.stub(:suite_for_current_branch?) { true }
      tddium_api.stub(:get_sessions).exactly(1).times.and_return([])
      expect {
        subject.describe
      }.to raise_error(SystemExit,
                       /There are no recent sessions on this branch./)
    end

    it "should exit with failure when no suite exists on current branch" do
      tddium_api.stub(:current_suite_id) { nil }
      tddium_api.should_not_receive(:get_sessions)
      expect {
        subject.describe
      }.to raise_error(SystemExit,
                       /There are no recent sessions on this branch./)
    end

    context "prints recent session if no session id specified" do
      before do
        tddium_api.stub(:current_suite_id) { suite_id }
        subject.stub(:suite_for_current_branch?) { true }
        tddium_api.stub(:get_sessions).exactly(1).times.and_return(get_sessions_result)
        tddium_api.should_receive(:query_session).with(session_id).and_return(query_session_result)
        subject.should_receive(:print_table)
      end

      it "should work for equal commits" do
        Tddium::Git.should_receive(:git_current_commit).and_return(git_commit)
        subject.describe
      end

      it "should work when the worspace is ahead" do
        Tddium::Git.should_receive(:git_current_commit).and_return("#{git_commit}1")
        Tddium::Git.should_receive(:git_number_of_commits).and_return(1)
        subject.describe
      end

      it "should work when the worspace is behind" do
        Tddium::Git.should_receive(:git_current_commit).and_return("#{git_commit}1")
        Tddium::Git.should_receive(:git_number_of_commits).and_return(0, 1)
        subject.describe
      end
    end
  end
end
