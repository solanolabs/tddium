require 'rubygems'
require 'aruba/cucumber'
require 'pickle/parser'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"