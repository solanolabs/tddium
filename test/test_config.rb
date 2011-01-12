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
        @keys = %w(aws_key aws_secret test_pattern key_directory key_name result_directory server_tag ssh_tunnel)
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

