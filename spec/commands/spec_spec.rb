# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'msgpack_pure'
require 'tddium/cli'
require 'tddium/cli/commands/spec'

describe Tddium::TddiumCli do
  include_context "tddium_api_stubs"

  describe "#spec" do
    let(:commit_log_parser) { double(GitCommitLogParser) }
    let(:suite_id) { 1 }
    let(:suite) {{ "repoman_current" => true }}
    let(:session) { { "id" => 1 } }
    let(:latest_commit) { "latest_commit" }
    let(:test_executions) { { "started" => 1, "tests" => [], "session_done" => true, "session_status" => "passed"}}

    def stub_git
      Tddium::Git.stub(:git_changes?).and_return(false)
      Tddium::Git.stub(:git_push).and_return(true)
    end

    def stub_commit_log_parser
      commit_log_parser.stub(:commits).and_return([latest_commit])
      GitCommitLogParser.stub(:new).with(latest_commit).and_return(commit_log_parser)
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
      tddium_api.stub(:get_keys).and_return([{name: 'some_key', pub: 'some content'}])
    end

    it "should create a new session" do
      commits_encoded = Base64.encode64(MessagePackPure.pack([latest_commit]))
      cache_paths_encoded = Base64.encode64(MessagePackPure.pack(nil))
      cache_control_encoded = Base64.encode64(MessagePackPure.pack(
        'Gemfile' => Digest::SHA1.file("Gemfile").to_s,
        'Gemfile.lock' => Digest::SHA1.file("Gemfile.lock").to_s,
      ))
      repo_config_file_encoded = Base64.encode64(File.read('config/solano.yml'))
      tddium_api.stub(:get_suites).and_return([
        {"account" => "handle-2"},
      ])
      tddium_api.should_receive(:create_session).with(suite_id, 
                                        :commits_encoded => commits_encoded,
                                        :cache_control_encoded => cache_control_encoded,
                                        :cache_save_paths_encoded => cache_paths_encoded,
                                        :raw_config_file => repo_config_file_encoded)
      subject.scm.stub(:latest_commit).and_return(latest_commit)
      subject.spec
    end

    it "should not create a new session if a session_id is specified" do
      tddium_api.should_not_receive(:create_session)
      tddium_api.should_receive(:update_session)
      tddium_api.stub(:get_suites).and_return([
        {"account" => "handle-2"},
      ])
      subject.stub(:options) { {:session_id=>1} }
      subject.scm.stub(:latest_commit).and_return(latest_commit)
      subject.spec
    end

    it "should push to the public repo uri in CLI mode" do
      subject.stub(:options) { {:machine => false} }
      tddium_api.stub(:get_suites).and_return([
        {"account" => "handle-2"},
      ])
      subject.scm.stub(:latest_commit).and_return(latest_commit)
      subject.scm.should_receive(:push_latest).with(anything, anything, {}).and_return(true)
      subject.spec
    end

    it "should push to the private repo uri in ci mode" do
      subject.stub(:options) { {:machine => true} }
      subject.scm.stub(:latest_commit).and_return(latest_commit)
      subject.scm.should_receive(:push_latest).with(anything, anything, use_private_uri: true).and_return(true)
      subject.spec
    end
  end
end
