Before do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 1
  @dirs = [Dir.tmpdir, "aruba"]
  FileUtils.rm_rf(current_dir)
end
