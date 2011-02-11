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
      @path = File.expand_path(get_config_paths[0])
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
        @path = File.expand_path(get_config_paths[0])
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

  context "find_config" do
    should "check rails root if it's set" do
      oldroot = ENV['RAILS_ROOT']
      ENV['RAILS_ROOT'] = '/home/rails'
      File.expects(:exists?).with('/home/rails/.tddium')
      File.expects(:exists?).with(File.expand_path('~/.tddium'))
      File.expects(:exists?).with('.tddium')
      assert_nil find_config
      ENV['RAILS_ROOT'] = oldroot
    end

    should "find rails root file if it's there" do
      oldroot = ENV['RAILS_ROOT']
      ENV['RAILS_ROOT'] = '/home/rails'
      path = get_config_paths[0]
      assert_equal '/home/rails/.tddium', path
      File.open(path, 'w') {|f| f.write('a')}
      assert_equal path, find_config
      ENV['RAILS_ROOT'] = oldroot
    end
  end
end

class TestKeyFile < Test::Unit::TestCase
  context "get_keyfile" do
    setup do
      @config = {:key_directory => 'dir', :key_name => 'key'}
      stubs(:read_config => @config).once
      FakeFS::FileSystem.clear
    end

    context "no keyfile present" do
      should "return nil" do
        STDERR.expects(:puts).once
        assert_nil get_keyfile
      end
    end

    context "keyfile wrong perms" do
      should "return nil" do
        FileUtils.mkdir_p @config[:key_directory]
        File.open(key_file_name(@config), 'w') do |f|
          f.write 'abc'
        end
        FakeFS::File::Stat.mode=0644
        STDERR.expects(:puts).once
        assert_nil get_keyfile
      end
    end

    context "keyfile OK" do
      should "return keyfile name" do
        @name = key_file_name(@config)
        FileUtils.mkdir_p @config[:key_directory]
        File.open(@name, 'w') do |f|
          f.write 'abc'
        end
        FakeFS::File::Stat.mode=0600
        STDERR.expects(:puts).never
        assert_equal @name, get_keyfile
      end
    end
  end
end

class TestFiles < Test::Unit::TestCase
  context "find_test_files" do
    setup do
      @config = {:test_pattern => 'a'}
      stubs(:read_config => @config)
    end
    
    should "be callable" do
      assert find_test_files
    end
  end
end

class TestSpecOpts < Test::Unit::TestCase
  context "spec_opts" do
    should "return a list" do
      stubs(:read_config => CONFIG_DEFAULTS)
      opts = spec_opts('a')
      assert opts.is_a?(Array)
      assert_equal 1, opts.select{|x| /require/.match(x)}.size
    end

    should "include require_files" do
      stubs(:read_config => {:require_files => 'a.rb'})
      opts = spec_opts('a')
      assert opts.is_a?(Array)
      assert_equal 2, opts.select{|x| /require/.match(x)}.size
    end

    should "read TDDIUM_SPEC_OPTS environment" do
      stubs(:read_config => CONFIG_DEFAULTS)
      specopts = 'abcdefgh'
      oldenv = ENV['TDDIUM_SPEC_OPTS']
      ENV['TDDIUM_SPEC_OPTS'] = specopts
      opts = spec_opts('a')
      ENV['TDDIUM_SPEC_OPTS'] = oldenv
      assert opts.is_a?(Array)
      assert_equal 1, opts.select{|x| /#{specopts}/.match(x)}.size
    end
  end
end
