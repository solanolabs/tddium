# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require File.expand_path("../tddium/constant", __FILE__)
require File.expand_path("../tddium/version", __FILE__)
require File.expand_path("../tddium/heroku", __FILE__)

module Tddium
  class TddiumError < Exception
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end
end
