# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

Given /^"([^"]*)" is a valid invitation token$/ do |arg1|
  Antilles.install(:post, "/1/users", SAMPLE_USER_RESPONSE, :code=>201)
end

Given /^"([^"]*)" is not a valid invitation token$/ do |arg1|
  Antilles.install(:post, "/1/users", {:status=>1, :explanation=>"unrecognized"}, :code=>409)
end
