module FileHelpers
  def tddium_global_config_file_path
    File.join(ENV["HOME"], ".tddium.mimic")
  end
end

World(FileHelpers)
