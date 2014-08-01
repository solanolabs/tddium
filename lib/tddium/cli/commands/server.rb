# Copyright (c) 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc 'server', "displays the saved connection info"

    def server
      self.class.display
    end

    desc 'server:set HOST [PORT] [PROTO] [INSECURE]', "saves connection info"

    method_option :host, type: :string, required: true
    method_option :port, type: :numeric, default: 443
    method_option :proto, type: :string, default: 'https'
    method_option :insecure, type: :boolean, default: false

    define_method 'server:set' do
      self.class.write_params options
    end
  end
end