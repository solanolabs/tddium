# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

When /^the console session ends$/ do
  begin
    @last_exit_status = @interactive.stop(true)
  rescue ArgumentError
    puts @interactive.inspect
    @interactive.stop(announcer, true)
  end
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

Then /^show me the file "([^"]*)"$/ do |file|
  prep_for_fs_check do
    puts IO.read(file)
  end
end

Then /^show me the output$/ do
  puts all_output
end
