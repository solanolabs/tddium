=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require 'helper'
require 'fakefs'
require 'fileutils'
require 'mocha'

class TestEC2 < Test::Unit::TestCase
  context "start instances" do
    setup do
      Fog.mock!
      @config = {:aws_key => 'abc', :aws_secret => 'def'}
      stubs(:read_config => @config)
      mockstart
    end

    should "create new EC2 instance with configured key" do
      server = start_instance
      assert_equal server.image_id, AMI_NAME
    end

    should "not crash if keyfile is not provided"

    context "if ssh_tunnel is needed" do
      setup do
        @config[:ssh_tunnel] = true
      end

      should "set up an ssh tunnel" do
        pid = 10
        stubs(:start_ssh_tunnel => true)
        Process.stubs(:fork).returns(pid)
        server = start_instance
      end
    end
  end
  
  context "stop instances" do
    setup do
      Fog.mock!
      config = {:aws_key => 'abc', :aws_secret => 'def'}
      stub(:read_config => config)
      mockstart
    end

    should "stop instances" do
      server = start_instance
      assert server.ready?
      stop_instance
      assert server.terminated?
    end

    should "destroy ssh tunnel"
  end

  private

    def mockstart
      httpmock = mock()
      httpmock.expects(:open_timeout=)
      httpmock.expects(:read_timeout=)
      httpmock.expects(:request)
      Net::HTTP.stubs(:new).returns(httpmock)
      getmock = mock()
      Net::HTTP::Get.stubs(:new).returns(getmock)
    end
end

class TestLogRotate < Test::Unit::TestCase
  context "calling result_directory" do
    setup do
      @config = {:result_directory => 'results'}
      @latest = File.join(@config[:result_directory], 'latest')
      stubs(:read_config => @config)
    end
    context "regardless" do
      should "return directory name" do
        x = result_directory
        assert_equal @latest, x
      end
    end
    context "with no results" do
      setup do
        FakeFS::FileSystem.clear
      end
      should "create results/latest/" do
        result_directory
        assert File.directory?(@latest)
      end
    end
    
    context "with existing <results>/latest directory" do
      setup do
        FileUtils.mkdir_p @latest
      end

      should "rotate latest to date-extended directory name" do
        result_directory
        files = Dir.glob("#{@config[:result_directory]}/*")
        puts files
        assert_equal 2, files.length
      end

      should "preserve contents of rotated report" do
        fname = File.join(@latest, 'report.html')
        File.open(fname, 'w') do |f|
          f.write('foo')
        end
        result_directory
        assert !File.exists?(fname)
        files = Dir.glob('**/report.html')
        assert_equal 1, files.length
        assert_equal 'foo', File.open(files[0]).read
      end
    end
  end

  context "default result path" do
    setup do
      @config = {:result_directory => "results"}
      stubs(:read_config => @config)
    end
    should "return the right path" do
      x = default_report_path
      expected = File.join(@config[:result_directory], 'latest', REPORT_FILENAME)
      assert_equal expected, x
    end
  end
end
