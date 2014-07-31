module ParamsHelper
  include TddiumConstant
  
  def load_params
    begin
      File.open(Default::PARAMS_PATH, mode = 'r') do |file|
        return JSON.parse file.read
      end
    rescue Exception => e
      {}
    end
  end

  def write_params options
    begin
      File.open(Default::PARAMS_PATH, File::CREAT|File::TRUNC|File::RDWR, 0600) do |file|
        file.write options.to_json
      end
      say Text::Process::PARAMS_SAVED
    rescue Exception => e
      say Text::Error::PARAMS_NOT_SAVED
    end
  end
end