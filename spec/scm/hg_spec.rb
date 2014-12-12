# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/scm/hg'

describe Tddium::Hg do
  let(:subject) { Tddium::Hg.new }

  def stub_hg(command, return_value)
    subject.stub(:`).with(/^hg #{command}/).and_return(return_value)
  end

  it "should have scm_name set" do
    expect(subject.scm_name).to eq("hg")
  end

  describe ".latest_commit" do
    before do
      stub_hg("log", "latest_commit")
    end

    it "should return the latest commit" do
      expect(subject).to receive(:`).with(/hg log -f -l 1/)
      expect(subject.send(:latest_commit)).to eq("latest_commit")
    end
  end

  describe ".push_latest" do
    let(:url) { "abc" }
    let(:private_url) { "def" }

    it "should set a public remote by default" do
      expect(subject).to receive(:hg_push).with(url)
      subject.push_latest({}, {"git_repo_uri" => url})
    end

    it "should set a public remote if requested" do
      expect(subject).to receive(:hg_push).with(url)
      subject.push_latest({}, {"git_repo_uri" => url}, {use_private_uri: false})
    end

    it "should set a private remote if requested" do
      expect(subject).to receive(:hg_push).with(private_url)
      subject.push_latest({}, {"git_repo_uri" => url, "git_repo_private_uri" => private_url}, {use_private_uri: true})
    end
  end
end
