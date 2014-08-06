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
end
