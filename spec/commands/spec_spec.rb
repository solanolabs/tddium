require 'spec_helper'
require 'msgpack'
require 'tddium/cli'
require 'tddium/cli/commands/spec'

describe Tddium::TddiumCli do
  include_context "tddium_api_stubs"

  describe "#spec" do
    let(:commit_log_parser) { mock(CommitLogParser) }
    let(:suite_id) { 1 }
    let(:suite) {{ "repoman_current" => true }}
    let(:session) { { "id" => 1 } }
    let(:latest_commit) { "latest_commit" }
    let(:test_executions) { { "started" => 1, "tests" => [], "session_done" => true, "session_status" => "passed"}}

    def stub_git
      Tddium::Git.stub(:git_changes?).and_return(false)
      Tddium::Git.stub(:update_git_remote_and_push).and_return(true)
      Tddium::Git.stub(:latest_commit).and_return(latest_commit)
    end

    def stub_commit_log_parser
      commit_log_parser.stub(:commits).and_return([latest_commit])
      CommitLogParser.stub(:new).with(latest_commit).and_return(commit_log_parser)
    end

    before do
      stub_git
      stub_commit_log_parser
      tddium_api.stub(:current_suite_id).and_return(suite_id)
      tddium_api.stub(:get_suite_by_id).and_return(suite)
      tddium_api.stub(:update_suite)
      tddium_api.stub(:create_session).and_return(session)
      tddium_api.stub(:register_session)
      tddium_api.stub(:start_session).and_return(test_executions)
      tddium_api.stub(:poll_session).and_return(test_executions)
    end

    it "should create a new session" do
      commits_encoded = Base64.encode64(MessagePack.pack([latest_commit]))
      cache_paths_encoded = Base64.encode64(MessagePack.pack(nil))
      cache_control_encoded = Base64.encode64(MessagePack.pack(
        'Gemfile' => Digest::SHA1.file("Gemfile").to_s,
        'Gemfile.lock' => Digest::SHA1.file("Gemfile.lock").to_s,
      ))
      tddium_api.should_receive(:create_session).with(suite_id, 
                                        :commits_encoded => commits_encoded,
                                        :cache_control_encoded => cache_control_encoded,
                                        :cache_save_paths_encoded => cache_paths_encoded)
      subject.spec
    end

    it "should not create a new session if a session_id is specified" do
      tddium_api.should_not_receive(:create_session)
      tddium_api.should_receive(:update_session)
      subject.stub(:options) { {:session_id=>1} }
      subject.spec
    end
  end
end
