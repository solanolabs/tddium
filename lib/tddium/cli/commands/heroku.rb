# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "heroku", "Connect Heroku account with Tddium (deprecated)"
    method_option :email, :type => :string, :default => nil
    method_option :password, :type => :string, :default => nil
    method_option :ssh_key_file, :type => :string, :default => nil
    method_option :app, :type => :string, :default => nil
    def heroku
      say "To activate your heroku account, please visit"
      say "https://api.tddium.com/"
    end
  end
end
