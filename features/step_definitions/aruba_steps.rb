
When /^the console session ends$/ do
  @last_exit_status = @interactive.stop(true)
end
