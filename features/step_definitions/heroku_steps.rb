Given /^the user has configured the Heroku add\-on$/ do
  prepend_path('features/bin')
  ENV['TDDIUM_HEROKU_COMMAND'] = 'heroku-stub'
  ENV['TDDIUM_HEROKU_STUB_API_KEY'] = 'apikey'
  ENV['TDDIUM_HEROKU_STUB_RESULT'] = '0'

  Antilles.install(:get, "/1/users", SAMPLE_HEROKU_USER_RESPONSE)

  # XXX Check options here
  Antilles.install(:put, "/1/users/1/", {:status=>0})
end

Given /^the heroku command fails$/ do
  prepend_path('features/bin')
  ENV['TDDIUM_HEROKU_COMMAND'] = 'heroku-stub'
  ENV['TDDIUM_HEROKU_STUB_RESULT'] = '1'
end

Given /^the heroku command is not found$/ do
  prepend_path('features/bin')
  ENV['TDDIUM_HEROKU_COMMAND'] = 'heroku-nonexistent'
end

Given /^the user a heroku config with an invalid API key$/ do
  prepend_path('features/bin')
  ENV['TDDIUM_HEROKU_COMMAND'] = 'heroku-stub'
  ENV['TDDIUM_HEROKU_STUB_API_KEY'] = 'apikey'
  ENV['TDDIUM_HEROKU_STUB_RESULT'] = '0'

  Antilles.install(:get, "/1/users", {:status=>1, :explanation=>"Unauthorized"}, :code=>403)
end

