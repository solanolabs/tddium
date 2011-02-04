=begin
Copyright (c) 2010 tddium.com All Rights Reserved
=end

# Subprocess main body to create an ssh tunnel to hostname for selenium, binding
# remote:4444 to local:4444. Authenticate with the private key in key_file.
# 
# The ssh tunnel will auto-accept the remote host key.
def ssh_tunnel(hostname)
  ssh_up = false
  tries = 0
  while !ssh_up && tries < 3
    sleep 3
    ssh_up = remote_cmd(hostname, "-L 4444:#{hostname}:4444 -N")
    tries += 1
  end
end

def make_ssh_tunnel(key_file, server)
  $tunnel_pid = nil
  if !key_file.nil? then
    $tunnel_pid = Process.fork do
      ssh_tunnel(server.dns_name)
    end

    STDERR.puts "Created ssh tunnel to #{server.dns_name}:4444 at localhost:4444 [pid #{$tunnel_pid}]"
  end
end

def kill_tunnel
  if !$tunnel_pid.nil?
    Process.kill("TERM", $tunnel_pid)
    Process.waitpid($tunnel_pid)
    $tunnel_pid = nil
  end
end


def remote_cmd(host, cmd)
  key_file = get_keyfile

  system("ssh -o 'StrictHostKeyChecking no' -i #{key_file} ec2-user@#{host} '#{cmd}'")
end

def remote_cp(host, remote_file, local_file)
  key_file = get_keyfile
  system("scp -o 'StrictHostKeyChecking no' -i #{key_file} ec2-user@#{host}:#{remote_file} #{local_file}")
end

