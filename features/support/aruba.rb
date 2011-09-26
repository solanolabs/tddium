# Copyright (c) 2011 Solano Labs All Rights Reserved

Before do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 2
  @dirs = [Dir.tmpdir, "aruba"]
  FileUtils.rm_rf(current_dir)
end
