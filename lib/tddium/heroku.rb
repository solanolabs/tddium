=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class HerokuConfig
  def self.read_config
    result = nil
    begin
      config = {}
      output = `heroku config -s`
      output.lines.each do |line|
        line.chomp!
        k, v = line.split('=')
        if k =~ /^TDDIUM_/ && v.length > 0
          config[k] = v
        end
      end
      result = config if config.keys.length > 0
    rescue Errno::ENOENT
    rescue Errno::EPERM
    end
    result
  end
end
