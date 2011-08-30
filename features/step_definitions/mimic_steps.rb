Given /^the user can log in and gets API key "([^"]*)"$/ do |apikey|
  MimicServer.server.install(:post, "/1/users/sign_in", {:status=>0, :api_key=>apikey})
end

Given /^the user cannot log in$/ do
  MimicServer.server.install(:post, "/1/users/sign_in", {:status=>1, :explanation=>"Access Denied."}, :code=>403)
end

When /^the console session ends$/ do
  @last_exit_status = @interactive.stop(true)
end
