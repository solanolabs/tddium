# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

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
      subject.should_receive(:suite_for_default_branch?).and_return(false)
      tddium_api.should_receive(:get_sessions).once.and_return([])
      subject.status
    end

    context "with suite and valid current branch" do
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

    context "with suite, invalid current and valid default branches" do
      before do
        subject.stub(:suite_for_current_branch?) { false }
        subject.stub(:suite_for_default_branch?) { true }
        tddium_api.stub(:default_suite_id) { suite_id }
        tddium_api.stub(:default_branch) { "branch" }
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

  describe "#show_session_details" do
    let(:output) { subject.send(:capture_stdout) { subject.send(:show_session_details, "xxx", {:suite_id => 1}, "X", "Y-%s-") } }

    it "shows empty" do
      expect(tddium_api).to receive(:get_sessions).once.and_return([])
      output = subject.send(:capture_stdout) { subject.send(:show_session_details, "xxx", {}, "X", "Y") }
      expect(output).to eq "\nX\n"
    end

    context "with a session" do
      let(:session) {{"commit" => "12345671234567", "id" => "111", "status" => "running", "duration" => 123, "start_time" => Time.now.to_s}}

      before do
        now = Time.now
        expect(Time).to receive(:now).at_least(:once).and_return Time.at(now.to_i)
        expect(tddium_api).to receive(:get_sessions).once.and_return([session])
      end

      it "shows normal" do
        expect(output).to eq "\nY-xxx-\n\nSession #  Commit   Status   Duration  Started\n---------  ------   ------   --------  -------\n111        1234567  running  123s      0 secs ago\n"
      end

      it "shows current head" do
        expect_any_instance_of(Tddium::Git).to receive(:current_commit).and_return session["commit"]
        expect(output).to eq "\nY-xxx-\n\nSession #  Commit   Status   Duration  Started\n---------  ------   ------   --------  -------\n111        \e[7m1234567\e[0m  running  123s      0 secs ago\n"
      end
    end
  end
end
