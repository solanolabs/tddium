# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

class Aruba::Process
  def kill(keep_ansi)
    stdout(keep_ansi) && stderr(keep_ansi) # flush output
    @process.stop
  end

  def find_in_output(str, chan=:all)
    total_wait = 0.0
    sleep_time = 0.2

    out = ''
    while total_wait < @io_wait
      @out.rewind
      @err.rewind

      check = case chan
              when :all
                @out.read + @err.read
              when :out
                @out.read
              when :err
                @err.read
              end


      out = filter_ansi(check, false)
      if out.include?(str)
        return [true, nil]
      end

      total_wait += sleep_time
      sleep sleep_time
    end
    return [false, out]
  end

  def expect(str, resp)
    resp = resp.chomp << "\n"
    if find_in_output(str)
      stdin.write(resp)
      stdin.flush
    else
      raise "couldn't find #{str}"
    end
  end
end

Before do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 5
  @dirs = [Dir.tmpdir, "tddium-aruba"]
  FileUtils.rm_rf(current_dir)
  
  FileUtils.rm_rf(tddium_homedir_path)
  FileUtils.mkdir_p(tddium_homedir_path)
  ENV['HOME'] = tddium_homedir_path
  FileUtils.rm_f(File.join(ENV['HOME'], '.tddium.*'))
end
