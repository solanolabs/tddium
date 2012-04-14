# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require File.expand_path(File.join(File.dirname(__FILE__), "tddium/constant"))
require File.expand_path(File.join(File.dirname(__FILE__), "tddium/version"))
require File.expand_path(File.join(File.dirname(__FILE__), "tddium/heroku"))

module Tddium
  class TddiumError < Exception
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end
end
