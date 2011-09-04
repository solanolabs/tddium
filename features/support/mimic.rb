# Copyright (c) 2011 Solano Labs All Rights Reserved

require 'antilles/cucumber'

tid = ENV['TDDIUM_TID'] || 0
port = 8500 + tid.to_i
ENV['TDDIUM_CLIENT_PORT'] = port.to_s
ENV['TDDIUM_CLIENT_ENVIRONMENT'] = 'mimic'

Antilles.configure do |server|
  server.log = STDOUT
  server.port = port
end
