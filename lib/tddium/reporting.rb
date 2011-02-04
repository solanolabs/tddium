=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end
#
# Prepare the result directory, as specified by config[:result_directory].
#
# If the directory doesn't exist create it, and a latest subdirectory.
#
# If the latest subdirectory exists, rotate it and create a new empty latest.
#
def result_directory
  conf = read_config
  latest = File.join(conf[:result_directory], 'latest')

  if File.directory?(latest) then
    mtime = File.stat(latest).mtime.strftime("%Y%m%d-%H%M%S")
    archive = File.join(conf[:result_directory], mtime)
    FileUtils.mv(latest, archive)
  end
  FileUtils.mkdir_p latest
  latest
end

REPORT_FILENAME = "selenium_report.html"

def default_report_path
  File.join(read_config[:result_directory], 'latest', REPORT_FILENAME)
end

def collect_syslog(target_directory='.')
  keyfile = get_keyfile
  if keyfile.nil?
    raise "No ssh keyfile configured.  Can't connect to remote"
  end
  instances = session_instances(@tddium_session ? @tddium_session : DEV_SESSION_KEY)
  instances.each do |inst|
    %w(selenium-hub selenium-rc).each do |log|
      remote_cp(inst.dns_name, "/var/log/#{log}.log",
                File.join(target_directory, "#{log}.#{inst.dns_name}"))
    end
  end
end
