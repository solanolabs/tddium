=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require 'helper'
require 'fakefs'
require 'fileutils'
require 'mocha'

class FakeFS::File::Stat
  attr_accessor :mode
end

class TestEC2 < Test::Unit::TestCase
  context "start instances" do
    setup do
      Fog.mock!
      @config = {:aws_key => 'abc', :aws_secret => 'def'}
      stubs(:read_config => @config)
      stubs(:system => 0)
      mockstart
    end

    should "create new EC2 instance with configured key" do
      server = start_instance
      assert_equal server.image_id, AMI_NAME
      assert_equal nil, $tunnel_pid
    end

    should "not crash if keyfile is not provided"

    should "set SELENIUM_RC_HOST environment variable" do
      server = start_instance
      assert_equal server.dns_name, ENV['SELENIUM_RC_HOST']
    end

    should "set TDDIUM environment variable" do
      server = start_instance
      assert_equal '1', ENV['TDDIUM']
    end

    context "if ssh_tunnel is needed" do
      setup do
        @config[:ssh_tunnel] = 1
        @config[:key_name] = 'sg-keypair'
        @config[:key_directory] = '.'
        FakeFS::FileSystem.clear
        File.open(key_file_name(@config), 'w', 0600) do |f|
          f.write('foo')
        end
        @testpid = 10000
        Process.stubs(:fork => @testpid)
      end

      should "set up an ssh tunnel and save its pid" do
        server = start_instance
        assert_equal @testpid,  $tunnel_pid
      end

      should "set the SELENIUM_RC_HOST environment variable to localhost" do
        server = start_instance
        assert_equal 'localhost', ENV['SELENIUM_RC_HOST']
      end
    end
  end
  
  context "stop instance" do
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

    should "kill tunnel process if it was created" do
      @testpid = 10000
      $tunnel_pid = @testpid
      Process.expects(:kill).with("TERM", @testpid)
      Process.expects(:waitpid).with(@testpid)
      server = start_instance
      stop_instance
    end

    should "not kill tunnel pid if it wasn't set" do
      $tunnel_pid = nil
      Process.expects(:kill).never
      server = start_instance
      stop_instance
    end
  end

  context "find_instances" do
    setup do
      Fog.mock!
      config = {:aws_key => 'abc', :aws_secret => 'def'}
      stub(:read_config => config)
    end

    should "exist as a method" do
      find_instances
    end

    should "not find any instances" do
      result = find_instances
      assert_nil result
    end

    should "find an instance" do
      mockstart
      server = start_instance
      result = find_instances
      assert_equal server.id, result[0].id
    end

    should "not filter by tag"
  end

  context "session_instances" do
    setup do
      Fog.mock!
      config = {:aws_key => 'abc', :aws_secret => 'def'}
      stub(:read_config => config)
      stop_all_instances
    end

    should "exist as a method" do
      session_instances
    end

    should "not find any instances" do
      result = session_instances
      assert_nil result
    end

    should "find an instance" do
      mockstart
      server = start_instance
      result = session_instances
      assert_equal server.id, result[0].id
    end
  end

  context "stopall instances" do
    setup do
      Fog.mock!
      config = {:aws_key => 'abc', :aws_secret => 'def'}
      stub(:read_config => config)
    end

    should "exist as a method" do
      stop_all_instances
    end

    should "destroy all instances" do
      instancemock = mock().expects(:destroy)
      instances = [instancemock, instancemock]
      stub(:find_instances => instances)
      stop_all_instances
    end
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

class TestSshTunnel < Test::Unit::TestCase
  should "have ssh tunnel method" do
    stubs(:system => true)
    ssh_tunnel('abc', 'def')
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

