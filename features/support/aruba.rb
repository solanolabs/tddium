# Copyright (c) 2011 Solano Labs All Rights Reserved

class Aruba::Process
  def kill(keep_ansi)
    stdout(keep_ansi) && stderr(keep_ansi) # flush output
    @process.stop
  end

  def expect(str, resp)
    total_wait = 0.0
    sleep_time = 0.2

    resp = resp.chomp << "\n"

    while total_wait < @io_wait
      @out.rewind
      @err.rewind

      out = filter_ansi(@out.read + @err.read, false)
      if out =~ /#{str}/
        stdin.write(resp)
        break
      end

      total_wait += sleep_time
      sleep sleep_time
    end
  end
end

Before do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 5
  @dirs = [Dir.tmpdir, "tddium-aruba"]
  FileUtils.rm_rf(current_dir)
  FileUtils.rm_f(File.join(ENV['HOME'], '.tddium.mimic'))
end
