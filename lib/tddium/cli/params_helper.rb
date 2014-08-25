# Copyright (c) 2014 Solano Labs All Rights Reserved

module ParamsHelper
  include TddiumConstant
  
  def load_params(defaults=true)
    params = {}
    if File.exists?(Default::PARAMS_PATH) then
      File.open(Default::PARAMS_PATH, 'r') do |file|
        params = JSON.parse file.read
      end
    elsif !defaults then
      abort Text::Process::NOT_SAVED_OPTIONS
    end
    return params
  end

  def write_params options
    begin
      File.open(Default::PARAMS_PATH, File::CREAT|File::TRUNC|File::RDWR, 0600) do |file|
        file.write options.to_json
      end
      say Text::Process::OPTIONS_SAVED
    rescue Exception => e
      say Text::Error::OPTIONS_NOT_SAVED
    end
  end

  def display
    store_params = load_params(false)
    say 'Options:'
    store_params.each do |k, v|
      say "   #{k.capitalize}:\t#{v}"
    end
  end
end
