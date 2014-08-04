# Copyright (c) 2014 Solano Labs All Rights Reserved

module ParamsHelper
  include TddiumConstant
  
  def load_params
    begin
      File.open(Default::PARAMS_PATH, 'r') do |file|
        return JSON.parse file.read
      end
    rescue Errno::ENOENT => e
      # when was called from class 'TddiumCli', return {} to use default options
      if caller[1][/`([^']*)'/, 1] == '<class:TddiumCli>'
       {}
      # when user wants to display options, but file not exist
      else
        abort Text::Process::NOT_SAVED_OPTIONS
      end
    end
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
    store_params = load_params
    say 'Options:'
    store_params.each do |k, v|
      say "   #{k.capitalize}:\t#{v}"
    end
  end
end
