=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require 'helper'
require 'fakefs'
require 'mocha'

class TestFileops < Test::Unit::TestCase
  context "init task" do
    setup do
      @path = File.expand_path(CONFIG_FILE_PATH)
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
        File.new(@path, 'w').write('a')
      end

      should "print a warning message" do
        HighLine.expects(:ask).never
        init_task
      end
    end
  end
end

class TestConfigRead < Test::Unit::TestCase
  context "read config" do
    context "file exists" do
      setup do
        @path = File.expand_path(CONFIG_FILE_PATH)
      end

      should "read config file values into a dict" do
        File.open(@path, 'w') do |f|
          f.write <<EOF
aws_secret: abc
aws_key: abx
EOF
        end
        conf = read_config
        assert_equal conf[:aws_key], 'abx'
        assert_equal conf[:aws_secret], 'abc'
      end
    end

    context "file doesn't exist" do
      should "return nils" do
        conf = read_config
        assert_nil conf[:aws_key]
        assert_nil conf[:aws_secret]
      end
    end
  end
end

class TestEC2 < Test::Unit::TestCase
  context "start instances" do
    setup do
      Fog.mock!
      config = {:aws_key => 'abc', :aws_secret => 'def'}
      stub(:read_config => config)
      httpmock = mock()
      httpmock.expects(:open_timeout=)
      httpmock.expects(:read_timeout=)
      httpmock.expects(:request)
      Net::HTTP.stubs(:new).returns(httpmock)
      getmock = mock()
      Net::HTTP::Get.stubs(:new).returns(getmock)
    end
    should "create new EC2 instance with configured key" do
      c = Fog::AWS::Compute.new
      server = start_instance
      assert_equal server.image_id, AMI_NAME
    end
  end
  
  context "stop instances" do
    setup do
      Fog.mock!
      config = {:aws_key => 'abc', :aws_secret => 'def'}
      stub(:read_config => config)
      server = start_instance
      assert server.ready?
      stop_instance
      assert server.terminated?
    end
  end
end


