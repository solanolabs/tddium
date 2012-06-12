# Copyright (c) 2011 Solano Labs All Rights Reserved

require 'rubygems'
require 'aruba/cucumber'
require 'pickle/parser'

def prepend_path(path)
  path = File.expand_path(File.dirname(__FILE__) + "/../../#{path}")
  ENV['PATH'] = "#{path}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
end

prepend_path('bin')
#ENV['COVERAGE'] = "true"
ENV['COVERAGE_ROOT'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../')}"

