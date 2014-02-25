require 'spec_helper'
require 'tddium/cli'
require 'tddium/cli/commands/find_failing'
require 'tmpdir'

describe Tddium::TddiumCli do
  describe "#find_failing" do
    include_context "tddium_api_stubs"

    def write(file, content)
      File.open(file, "w") { |f| f.write(content) }
    end

    def run_valid_order
      subject.find_failing(["a.rb", "b.rb", "c.rb", "c.rb"])
    end

    around do |test|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir, &test)
      end
    end

    before do
      write "a.rb", "$a=1"
      write "b.rb", "$b=1"
      write "c.rb", "exit($b || 0)"
      subject.stub(:say)
    end

    it "fails with missing failure" do
      expect {
        subject.find_failing(["a.rb", "b.rb", "c.rb"])
      }.to raise_error(SystemExit, /Files have to include the failing file/)
    end

    it "fails with to few files" do
      expect {
        subject.find_failing(["a.rb", "a.rb"])
      }.to raise_error(SystemExit, /Files have to be more than 2/)
    end

    it "fail quickly when there is no failure" do
      write "c.rb", "exit(0)"
      expect {
        run_valid_order
      }.to raise_error(SystemExit, /tests pass locally/)
    end

    it "fail quickly when file itself faiks" do
      write "c.rb", "exit(1)"
      expect do
        run_valid_order
      end.to raise_error(SystemExit, /c.rb fails when run on it's own/)
    end

    it "find the polluter" do
      subject.should_receive(:say).with("Fails when b.rb, c.rb are run together")
      run_valid_order
    end

    it "finds the polluter in a bigger set" do
      10.times { |i| write "#{i}.rb", "$a#{i}=1" }
      subject.should_receive(:say).with("Fails when b.rb, c.rb are run together")
      subject.find_failing(["a.rb", "0.rb", "1.rb", "2.rb", "b.rb", "3.rb", "4.rb", "5.rb", "6.rb", "7.rb", "c.rb", "8.rb", "9.rb", "c.rb"])
    end
  end
end
