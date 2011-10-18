# Copyright (c) 2011 Solano Labs All Rights Reserved

class Aruba::Process
  def kill(keep_ansi)
    stdout(keep_ansi) && stderr(keep_ansi) # flush output
    @process.stop
  end
end

Before do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 1.3
  @dirs = [Dir.tmpdir, "tddium-aruba"]
  FileUtils.rm_rf(current_dir)
end
