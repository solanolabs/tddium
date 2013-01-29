module FileHelpers
  def tddium_global_config_file_path
    File.join(ENV["HOME"], ".tddium.mimic")
  end

  def tddium_homedir_path
    File.join(Dir.tmpdir, "tddium-aruba", "tmphome")
  end
end

World(FileHelpers)
