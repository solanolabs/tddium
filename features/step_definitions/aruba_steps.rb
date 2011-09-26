# Copyright (c) 2011 Solano Labs All Rights Reserved

When /^the console session ends$/ do
  @last_exit_status = @interactive.stop(true)
end
