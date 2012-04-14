# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

#require 'simplecov'
#SimpleCov.start

require 'tddium'

require 'rspec'
require 'fakefs/spec_helpers'
require 'tddium_client/tddium_spec_helpers'

require 'ostruct'
require 'stringio'
require 'fileutils'

class Open3SpecHelper
  def self.stubOpen2e(data, ok, block)
    stdin = StringIO.new
    output = StringIO.new(data)
    status = (ok && 0) || 1
    value = OpenStruct.new(:exitstatus => status, :to_i => status)
    wait = OpenStruct.new(:value => value)
    block.call(stdin, output, wait)
  end
end

def env_save
  return ENV.to_hash.dup
end

def env_restore(env)
  env.each_pair do |k, v|
    ENV[k] = v
  end
end
