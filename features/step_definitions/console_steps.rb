# Copyright (c) 2012 Solano Labs All Rights Reserved

Given /^the user has an active SSH session$/ do
  user = 'u208'
  host = 'localhost'
  key = load_feature_fixture("ssh_rsa_key.pub")
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/sshauth",
                   {:status=>0, :user => user, :host => host, :keys => [key]},
                   :code=>201)
end
