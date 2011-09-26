# Copyright (c) 2011 Solano Labs All Rights Reserved

Given /^the command is "([^"]*)"$/ do |command|
  @command = command
end

When /^I respond to "([^"]*)" with "([^"]*)"$/ do |expect, response|
  cmd = @command || "tddium suite"
  steps %Q{
Then the output from "#{cmd}" should contain "#{expect}"
When I type "#{response}"
  }
end
