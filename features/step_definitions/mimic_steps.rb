# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

Given /^the command is "([^"]*)"$/ do |command|
  @command = command
end

When /^I respond to "([^"]*)" with "([^"]*)"$/ do |str, response|
  cmd = @command || "tddium suite"
  get_process(cmd).expect(str, response)
  puts "matched #{str} and wrote #{response}"
end
