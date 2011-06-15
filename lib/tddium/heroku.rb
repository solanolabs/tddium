=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require 'timeout'

class HerokuConfig
  class HerokuError < RuntimeError; end
  class HerokuNotFound < HerokuError; end
  class TddiumNotAdded < HerokuError; end
  class InvalidFormat < HerokuError; end
  class NotLoggedIn < HerokuError; end
  class AppNotFound < HerokuError; end

  REQUIRED_KEYS = %w{TDDIUM_API_KEY TDDIUM_USER_NAME}
  def self.read_config(app=nil)
    config = {}
    
    command = "heroku config -s"
    command += " --app #{app}" if app

    begin
      output = `#{command} < /dev/null 2>&1`
    rescue Errno::ENOENT
      raise HerokuNotFound
    end
    raise HerokuNotFound if output =~ /heroku: not found/
    raise AppNotFound if output =~ /App not found/
    raise InvalidFormat if output.length == 0
    raise NotLoggedIn if output =~ /Heroku credentials/

    output.lines.each do |line|
      line.chomp!
      k, v = line.split('=')
      if k =~ /^TDDIUM_/ && v.length > 0
        config[k] = v
      end
    end
    raise TddiumNotAdded if config.keys.length == 0
    raise InvalidFormat if REQUIRED_KEYS.inject(false) {|missing, x| missing || !config[x]}
    config
  end
end