# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

Given /^`tddium keys` will write into tmp storage$/ do
  ENV['TDDIUM_GEM_KEY_DIR'] = current_dir
end

Given /^the user has the following keys:$/ do |table|
  key_data = table.hashes
  key_data.each do |k|
    k[:pub] = load_feature_fixture("ssh_rsa_key.pub")
  end
  Antilles.install(:get, "/1/keys", {:status=>0, :keys=>key_data})
end

Given /^the user has no keys$/ do 
  Antilles.install(:get, "/1/keys", {:status=>0, :keys=>nil})
end

Given /^there is a problem retrieving keys$/ do
  Antilles.install(:get, "/1/keys", {:status=>1, :explanation=>"problem"}, :code=>409)
end

Given /^adding the key "([^"]*)" will succeed$/ do |arg1|
  Antilles.install(:post, "/1/keys", {:status=>0}, :code=>201)
end

Given /^adding the key "([^"]*)" will fail$/ do |arg1|
  Antilles.install(:post, "/1/keys", {:status=>1, :explanation=>"problem"}, :code=>409)
end

Then /^the key file named "([^"]*)" should exist$/ do |arg1|
  steps %Q{
    Then a file named "identity.tddium.#{arg1}" should exist
  } 
end

Then /^the key file named "([^"]*)" should not exist$/ do |arg1|
  steps %Q{
    Then the file "identity.tddium.#{arg1}" should not exist
  } 
end

Given /^the public key file named "([^"]*)" exists$/ do |arg1|
  steps %Q{
    Given a file named "identity.tddium.#{arg1}.pub" with:
    """
    ssh-rsa SOME DATA
    """
  } 
end

Given /^the private key file named "([^"]*)" exists$/ do |arg1|
  steps %Q{
    Given a file named "identity.tddium.#{arg1}" with:
    """
    -----BEGIN RSA PRIVATE KEY-----
    ABCDEF
    -----END RSA PRIVATE KEY-----
    """
  } 
end

Given /^removing the key "([^"]*)" will succeed$/ do |arg1|
  Antilles.install(:delete, "/1/keys/#{arg1}", {:status=>0}, :code=>200)
end

Given /^removing the key "([^"]*)" will fail$/ do |arg1|
  Antilles.install(:delete, "/1/keys/#{arg1}", {:status=>1, :explanation=>"problem"}, :code=>409)
end
