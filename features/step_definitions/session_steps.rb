Given /^the user can create a session$/ do
  Antilles.install(:post, "/1/sessions",
                   {:status=>0, :session=>{"id"=>SAMPLE_SESSION_ID}},
                   :code=>201)
end

Given /^the user successfully registers tests for the suite(?: with test_pattern: (.*))?$/ do |pattern|
  options = {}
  if pattern == 'default'
    options['params'] = {'suite_id'=>SAMPLE_SUITE_ID, 'test_pattern'=>nil}
  elsif pattern
    options['params'] = {'suite_id'=>SAMPLE_SUITE_ID, 'test_pattern'=>pattern.gsub(/"/,'')}
  end
  res = Antilles.install(:post, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions/register", {:status=>0}, options)
  puts res.parsed_response
end

Given /^the tests start successfully$/ do
  Antilles.install(:post, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions/start", SAMPLE_START_TEST_EXECUTIONS_RESPONSE)
end

Given /^the tests? all pass$/ do
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions", SAMPLE_TEST_EXECUTIONS_PASSED_RESPONSE)
end

Given /^the tests? all fail$/ do
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions", SAMPLE_TEST_EXECUTIONS_FAILED_RESPONSE)
end

Given /^the test all pass with messages$/ do
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions", SAMPLE_TEST_EXECUTIONS_MESSAGE_RESPONSE)
end

Given /^the session completes$/ do
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/check_done", SAMPLE_CHECK_DONE_RESPONSE)
end

Given /^the test all pass with a warning message$/ do
  Antilles.install(:get, "/1/sessions/#{SAMPLE_SESSION_ID}/test_executions", SAMPLE_TEST_EXECUTIONS_WARNING_RESPONSE)
end

Then /^the output should contain the list of failed tests$/ do
  test_names = SAMPLE_TEST_EXECUTIONS_FAILED_RESPONSE['tests'].keys
  test_names.each do |tn|
    step %Q{the output should contain "#{tn}"}
  end
end

