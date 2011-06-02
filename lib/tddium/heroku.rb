=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class HerokuConfig
  REQUIRED_KEYS = %w{TDDIUM_API_KEY TDDIUM_USER_NAME}
  def self.read_config(app=nil)
    result = nil
    begin
      config = {}
      command = "heroku config -s"
      command += " --app #{app}" if app
      output = `#{command}`
      output.lines.each do |line|
        line.chomp!
        k, v = line.split('=')
        if k =~ /^TDDIUM_/ && v.length > 0
          config[k] = v
        end
      end
      return nil if REQUIRED_KEYS.inject(false) {|missing, x| !config[x]}
      result = config if config.keys.length > 0
    rescue 
    end
    result
  end
end
