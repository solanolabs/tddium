# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require "tddium/constant"
require "tddium/version"

require "tddium/scm"
require "tddium/ssh"

module Tddium
  class TddiumError < Exception
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end
end
