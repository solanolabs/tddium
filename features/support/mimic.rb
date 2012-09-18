# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require 'mimic'

module Mimic
  class FakeHost
    class StubbedRequest
      def unmatched_response
        res = [404, {}, '{"status":1, "explanation":"not found"}']
        puts "unmatched: #{res}"
        res
      end

      def matches?(request)
        if @params.any?
          req_params = {}
          if request.env["CONTENT_TYPE"] == 'application/json'
            req_params = JSON.parse(request.body.read)
          end
          req_params.merge!(request.params)
          puts "checking params... got: #{req_params.inspect}, expected: #{@params.inspect}"
          @params.all? do |k,v|
            req_params[k] == v
          end
        else
          true
        end
      end
    end
  end
end

require 'antilles/cucumber'

port = Antilles.find_available_port
ENV['TDDIUM_CLIENT_PORT'] = port.to_s
ENV['TDDIUM_CLIENT_ENVIRONMENT'] = 'mimic'

Antilles.configure do |server|
  server.log = STDOUT
  server.port = port
end
