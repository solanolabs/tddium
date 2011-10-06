Given /^the user can create a session$/ do
  Antilles.install(:post, "/1/sessions", {:status=>0, :session=>{"id"=>SAMPLE_SESSION_ID}}, :code=>201)
end

Given /^the user successfully registers tests for the suite$/ do
  Antilles.install(:post, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions/register", {:status=>0})
end

Given /^the tests start successfully$/ do
  Antilles.install(:post, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions/start", SAMPLE_START_TEST_EXECUTIONS_RESPONSE)
end

Given /^the test all pass$/ do
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions", SAMPLE_TEST_EXECUTIONS_PASSED_RESPONSE)
end


