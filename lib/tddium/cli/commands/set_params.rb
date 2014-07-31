# Copyright (c) 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc 'set_params [HOST] [PORT] [PROTO] [INSECURE]', "Save entered params, don't need later to call them again"

    method_option :host, type: :string, default: nil
    method_option :port, type: :numeric, default: nil
    method_option :proto, type: :string, default: 'https'
    method_option :insecure, type: :boolean, default: false

    def set_params
      self.class.write_params options
    end
  end
end