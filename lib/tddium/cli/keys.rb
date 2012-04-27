# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    protected

    def load_ssh_key(ssh_file, name)
      begin
        data = File.open(File.expand_path(ssh_file)) {|file| file.read}
      rescue Errno::ENOENT => e
        raise TddiumError.new(Text::Error::INACCESSIBLE_SSH_PUBLIC_KEY % [ssh_file, e])
      end

      if data =~ /^-+BEGIN \S+ PRIVATE KEY-+/ then
        raise TddiumError.new(Text::Error::INVALID_SSH_PUBLIC_KEY % ssh_file)
      end
      if data !~ /^\s*ssh-(dss|rsa)/ && data !~ /^\s*ecdsa-/ then
        raise TddiumError.new(Text::Error::INVALID_SSH_PUBLIC_KEY % ssh_file)
      end

      {:name=>name,
       :pub=>data, 
       :hostname=>`hostname`, 
       :fingerprint=>`ssh-keygen -lf #{ssh_file}`}
    end

    def generate_keypair(name, output_dir)
      filename = File.expand_path(File.join(output_dir, "identity.tddium.#{name}"))
      pub_filename = filename + ".pub"
      exit_failure Text::Error::KEY_ALREADY_EXISTS % filename if File.exists?(filename)
      cmd = "ssh-keygen -q -t rsa -P '' -C 'tddium.#{name}' -f #{filename}"
      exit_failure Text::Error::KEYGEN_FAILED % name unless system(cmd)
      {:name=>name,
       :pub=>File.read(pub_filename), 
       :hostname=>`hostname`, 
       :fingerprint=>`ssh-keygen -lf #{pub_filename}`}
    end
  end
end
