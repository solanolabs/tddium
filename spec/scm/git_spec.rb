# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/scm/git'

describe Tddium::Git do
  let(:subject) { Tddium::Git.new }

  def stub_git(command, return_value)
    subject.stub(:`).with(/^git #{command}/).and_return(return_value)
  end

  describe ".latest_commit" do
    before do
      stub_git("log", "latest_commit")
    end

    it "should return the latest commit" do
      subject.should_receive(:`).with("git log --pretty='%H%n%s%n%aN%n%aE%n%at%n%cN%n%cE%n%ct%n' HEAD^..HEAD")
      subject.send(:latest_commit).should == "latest_commit"
    end
  end

  describe ".push_latest" do
    let(:url) { "abc" }
    let(:private_url) { "def" }

    before do
      Tddium::Git.stub(:git_push).and_return(true)
    end

    it "should set a public remote by default" do
      expect(Tddium::Git).to receive(:git_set_remotes).with(url)
      subject.push_latest({}, {"git_repo_uri" => url})
    end

    it "should set a public remote if requested" do
      expect(Tddium::Git).to receive(:git_set_remotes).with(url)
      subject.push_latest({}, {"git_repo_uri" => url}, {use_private_uri: false})
    end

    it "should set a private remote if requested" do
      expect(Tddium::Git).to receive(:git_set_remotes).with(private_url)
      subject.push_latest({}, {"git_repo_uri" => url, "git_repo_private_uri" => private_url}, {use_private_uri: true})
    end
  end
end
