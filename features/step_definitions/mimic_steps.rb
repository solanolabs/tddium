Given /^the user can log in and gets API key "([^"]*)"$/ do |apikey|
  MimicServer.server.install(:post, "/1/users/sign_in", {:status=>0, :api_key=>apikey})
end

When /^the console session ends$/ do
  @last_exit_status = @interactive.stop
end
