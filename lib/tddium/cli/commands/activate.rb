# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "activate", "Activate an account (deprecated)"
    method_option :email, :type => :string, :default => nil
    method_option :password, :type => :string, :default => nil
    method_option :ssh_key_file, :type => :string, :default => nil
    def activate
      say "To activate your account, please visit"
      say "https://ci.solanolabs.com/"
    end
  end
end
