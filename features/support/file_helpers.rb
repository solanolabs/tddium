# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module FileHelpers
  def tddium_global_config_file_path
    File.join(ENV["HOME"], ".tddium.localhost")
  end

  def tddium_homedir_path
    File.join(Dir.tmpdir, "tddium-aruba", "tmphome")
  end
end

World(FileHelpers)
