# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

When /^the console session ends$/ do
  @last_exit_status = @interactive.stop(true)
end

When /^the console session is killed$/ do
  @interactive.kill(true)
  @last_exit_status = -1
end

def get_chan(raw)
  case raw
  when 'output'
    :all
  when 'stderr'
    :err
  when 'stdout'
    :out
  end
end

def check_contains(cmd, chan, pol, expected)
  res = get_process(cmd).find_in_output(expected, get_chan(chan))
  if !res[0]
    if pol == 'should'
      res[1].should include(expected)
    else
      res[1].should_not include(expected)
    end
  end
end

Then /^"([^"]*)" (output|stderr) (should|should not) contain:$/ do |cmd, chan, pol, expected|
  check_contains(cmd, chan, pol, expected)
end

Then /^"([^"]*)" (output|stderr) (should|should not) contain "([^"]*)"$/ do |cmd, chan, pol, expected|
  check_contains(cmd, chan, pol, expected)
end

