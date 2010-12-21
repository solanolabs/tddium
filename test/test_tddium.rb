require 'helper'
require 'fakefs'
require 'mocha'

class TestFileops < Test::Unit::TestCase
  context "init task" do
    setup do
      @path = File.expand_path('~/.tddium')
    end

    context "when ~/.tddium doesn't exist" do
      setup do
        FakeFS::FileSystem.clear
        HighLine.any_instance.stubs(:ask).returns('abc')
        init_task
      end
    
      should "write ~/.tddium" do
        assert File.exists?(@path), "#{@path} doesn't exist"
      end

      should "have the right contents" do
        f = FakeFS::FileSystem.find(@path)
        assert f.content.include?('abc'), "Should contain magic string"
        %w(aws_key aws_secret).each do |field|
          assert f.content.include?(field), "Should contain #{field}"
        end
      end
    end

    context "when ~/.tddium exists" do
      setup do
        FakeFS::FileSystem.add(@path)
      end

      should "print a warning message" do
        HighLine.expects(:ask).never
        init_task
      end
    end
  end
end

