# Copyright (c) 2011 Solano Labs All Rights Reserved

class Aruba::Process
  def kill(keep_ansi)
    stdout(keep_ansi) && stderr(keep_ansi) # flush output
    @process.stop
  end
end

Before do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 5
  @dirs = [Dir.tmpdir, "tddium-aruba"]
  FileUtils.rm_rf(current_dir)
  FileUtils.rm_f(File.join(ENV['HOME'], '.tddium.mimic'))
end
