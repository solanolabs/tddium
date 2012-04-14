# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/agent'

describe "Agent" do
  before(:each) do
    @exec_id = 42
    @session_id = 37
    @agent = Tddium::BuildAgent.new

    FakeFS.activate!

    FileUtils.mkdir_p(File.join(ENV['HOME'], 'tmp'))
  end

  after(:each) do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  it "should initialize" do
    lambda { agent = Tddium::BuildAgent.new }.should_not raise_error
  end

  it "should know whether we are running inside Tddium or not" do
    begin
      env = env_save

      ENV['TDDIUM'] = '1'
      @agent.tddium?.should be_true

      ENV.delete('TDDIUM')
      @agent.tddium?.should be_false
    ensure
      env_restore(env)
    end
  end

  it "should fetch various identifiers" do
    ids = [[:thread_id, 'TDDIUM_TID'], [:session_id, 'TDDIUM_SESSION_ID'],
           [:test_exec_id, 'TDDIUM_TEST_EXEC_ID']]

    ids.each do |method, var|
      begin
        val = 42
        env = env_save
        ENV['TDDIUM'] = '1'
        ENV[var] = val.to_s
        @agent.send(method).should == val
      ensure
        env_restore(env)
      end
    end
  end

  it "should detect Tddium environment" do
    [['interactive', 'interactive'], [nil, 'none']].each do |val, result|
      begin
        env = env_save
        ENV['TDDIUM_MODE'] = val
        @agent.environment.should == result
      ensure
        env_restore(env)
      end
    end
  end

  it "should refuse to attach a blob that is too big" do
    max = Tddium::BuildAgent::MAXIMUM_ATTACHMENT_SIZE

    blob = 'A'*(max+1)
    lambda { @agent.attach(blob, {}) }.should raise_error(Tddium::TddiumError)
  end

  it "should attach a named blob" do
    blob = 'A'*128

    guid = "01234567"
    metadata = {:name => "user.#{guid}.dat"}

    SecureRandom.should_receive(:hex).once.and_return(guid)

    @agent.should_receive(:attach_file).with(anything(), metadata).and_return(nil)
    @agent.attach(blob, metadata)
  end

  it "should attach an unnamed blob" do
    blob = 'A'*128

    guid = "01234567"
    metadata = {:name => "user.#{guid}.dat"}

    SecureRandom.should_receive(:hex).twice.and_return(guid)

    @agent.should_receive(:attach_file).with(anything(), metadata).and_return(nil)
    @agent.attach(blob, {})
  end

  it "should attach a file" do
    begin
      env = env_save
      ENV['TDDIUM_SESSION_ID'] = @session_id.to_s
      ENV['TDDIUM_TEST_EXEC_ID'] = @exec_id.to_s

      path = File.join(ENV['HOME'], 'tmp', 'user.dat')
      FileUtils.touch(path)

      attach_path = @agent.send(:attachment_path, 'user.dat', @exec_id)

      FileUtils.should_receive(:cp).with(path, attach_path)

      @agent.attach_file(path, {:exec_id => @exec_id})

    ensure
      env_restore(env)

    end
  end
end
