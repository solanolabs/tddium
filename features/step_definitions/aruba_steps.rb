# Copyright (c) 2011 Solano Labs All Rights Reserved

When /^the console session ends$/ do
  @last_exit_status = @interactive.stop(true)
end

When /^the console session is killed$/ do
  @interactive.kill(true)
  @last_exit_status = -1
end

Then /^the output from "([^"]*)" should contain:$/ do |cmd, expected|
  assert_partial_output(expected, output_from(cmd))
end

Then /^the output from "([^"]*)" should not contain "([^"]*)"$/ do |cmd, unexpected|
  assert_no_partial_output(unexpected, output_from(cmd))
end

Then /^the output should not contain "([^"]*)"$/ do |unexpected|
  assert_no_partial_output(unexpected, all_output)
end
