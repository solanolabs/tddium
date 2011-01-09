=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

require 'helper'
require 'fakefs'
require 'fileutils'
require 'mocha'

class TestFileops < Test::Unit::TestCase
  context "init task" do
    setup do
      @path = File.expand_path(CONFIG_FILE_PATH)
    end

    context "when ~/.tddium doesn't exist" do
      setup do
        FakeFS::FileSystem.clear
        HighLine.any_instance.stubs(:ask).returns('abc', 'def', 'ghi')
        @keys = %w(aws_key aws_secret test_pattern key_directory key_name result_directory server_tag)
        init_task
      end
    
      should "write ~/.tddium" do
        assert File.exists?(@path), "#{@path} doesn't exist"
      end

      should "have the right contents" do
        f = FakeFS::FileSystem.find(@path)
        assert f.content.include?('abc'), "Should contain magic string"
        @keys.each do |field|
          assert f.content.include?(field), "Should contain #{field}"
        end
      end

      should "write a YAML file with the right fields" do
        result = YAML::load_file(@path)
        @keys.each do |field|
          assert result.has_key?(field.to_sym), "Should contain #{field}"
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
---
:aws_secret: abc
:aws_key: abx
:test_pattern: **/*_spec.rb
EOF
        end
        conf = read_config
        assert_equal conf[:aws_key], 'abx'
        assert_equal conf[:aws_secret], 'abc'
        assert_equal conf[:test_pattern], '**/*_spec.rb'
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
      stubs(:read_config => config)
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

    should "not crash if keyfile is not provided"
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

class TestConvertConfig < Test::Unit::TestCase
  context "when old configuration exists" do
    setup do
      FakeFS::FileSystem.clear
      @path = File.expand_path(CONFIG_FILE_PATH)
      @oldpath = @path + ".old"
      @text = <<EOF
aws_secret: abc
aws_key: abx
test_pattern: **/*_spec.rb
EOF
      File.open(@path, 'w') do |f|
        f.write @text
      end
      convert_old_config
    end

    should "save old config" do
      assert File.exists? @oldpath
      assert File.exists?(@path)
      f = FakeFS::FileSystem.find(@oldpath)
      assert_equal f.content, @text
    end

    should "write YAML file" do
      old_conf = read_old_config @oldpath
      conf = read_config
      assert_equal conf, old_conf
    end
  end
end

