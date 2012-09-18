# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

Given /^the user has the following memberships in his account:$/ do |table|
  Antilles.install(:get, "/1/memberships", {:status=>0, :memberships=>table.hashes})
  @memberships = {}
  table.hashes.each do |row|
    @memberships[row['email']]=row
  end
end

Given /^adding a member to the account will succeed$/ do
  Antilles.install(:post, "/1/memberships", {:status=>0}, :code=>201)
end

Given /^adding a member to the account will fail with error "([^"]*)"$/ do |error|
  Antilles.install(:post, "/1/memberships", {:status=>1, :explanation=>error}, :code=>409)
end

Given /^removing "([^"]*)" from the account will succeed$/ do |member|
  Antilles.install(:delete, "/1/memberships/#{member}", {:status=>0}, :code=>200)
end

Given /^removing "([^"]*)" from the account will fail with error "([^"]*)"$/ do |member, error|
  Antilles.install(:delete, "/1/memberships/#{member}", {:status=>1, :explanation=>error}, :code=>409)
end

Then /^the ouptut should contain the third party key$/ do
  steps %Q{
    Then the output should contain "#{SAMPLE_THIRD_PARTY_PUBKEY}"
  }
end
