Given /^"([^"]*)" is a valid invitation token$/ do |arg1|
  Antilles.install(:post, "/1/users", SAMPLE_USER_RESPONSE, :code=>201)
end

