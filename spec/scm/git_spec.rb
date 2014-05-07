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
end
