# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

Given /^the user is logged in$/ do
  @api_key = "abcdef"
  Antilles.install(:get, "/1/users", SAMPLE_USER_RESPONSE)
  Antilles.install(:get, "/1/accounts/usage_by_account", SAMPLE_ACCOUNT_USAGE)
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"#{@api_key}"}
    """
  }
end

Given /^the user is logged in to multiple accounts$/ do
  Antilles.install(:get, "/1/users", SAMPLE_USER_THIRD_PARTY_KEY_RESPONSE)
  Antilles.install(:get, "/1/accounts/usage_by_account", SAMPLE_ACCOUNT_USAGE)
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"abcdef"}
    """
    And a tddium global config file exists with:
    """
    {"api_key":"hijklm"}
    """
  }
end

Given /^the user is logged in to a single account$/ do
  Antilles.install(:get, "/1/users", SAMPLE_USER_THIRD_PARTY_KEY_RESPONSE)
  Antilles.install(:get, "/1/accounts/usage_by_account", SAMPLE_ACCOUNT_USAGE)
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"abcdef"}
    """
    And a tddium global config file exists with:
    """
    {"api_key":"abcdef"}
    """
  }
end

Given /^the user is logged in with a third-party key$/ do
  @api_key = "abcdef"
  Antilles.install(:get, "/1/users", SAMPLE_USER_THIRD_PARTY_KEY_RESPONSE)
  Antilles.install(:get, "/1/accounts/usage_by_account", SAMPLE_ACCOUNT_USAGE)
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"#{@api_key}"}
    """
  }
end

Given /^the user has a .tddium for branch "(.*)"$/ do |branch|
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"#{@api_key}", "branches":{"#{branch}":{"id":1}}}
    """
  }
end

Given /^the user is logged in with a configured suite(?: on branch "(.*)")?$/ do |branch|
  @api_key = "abcdef"
  branch ||= "master"
  Antilles.install(:get, "/1/users", SAMPLE_USER_RESPONSE)
  Antilles.install(:get, "/1/accounts/usage_by_account", SAMPLE_ACCOUNT_USAGE)
  steps %Q{
    Given the user has a .tddium for branch "#{branch}"
    And the user has a suite for "repo" on "#{branch}"
  }
end

Given /^the user belongs to two accounts$/ do
  Antilles.install(:get, "/1/users", SAMPLE_USER_RESPONSE_2)
end

Given /^the user is logged in with a configured suite and remembered options$/ do
  @api_key = "abcdef"
  branch ||= "master"
  Antilles.install(:get, "/1/users", SAMPLE_USER_RESPONSE)
  Antilles.install(:get, "/1/accounts/usage_by_account", SAMPLE_ACCOUNT_USAGE)
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"#{@api_key}", "branches":{"#{branch}":{"id":1,"options":{"user_data_file":null,"max_parallelism":1,"test_pattern":"abc"}}}}
    """
    And the user has a suite for "repo" on "#{branch}"
  }
end


Given /^the user can log in and gets API key "([^"]*)"$/ do |apikey|
  Antilles.install(:post, "/1/users/sign_in", {:status=>0, :api_key=>apikey})
end

Given /^the user can log in with token "([^"]*)" and gets API key "([^"]*)"$/ do |token, apikey|
  options = {
    'params' => {'user'=>{'cli_token'=>token}}
  }
  Antilles.install(:post, "/1/users/sign_in", {:status=>0, :api_key=>apikey}, options)
end

Given /^the user cannot log in$/ do
  Antilles.install(:post, "/1/users/sign_in", {:status=>1, :explanation=>"Access Denied."}, :code=>403)
end

Given /^a tddium global config file exists(?: with:)$/ do |content|
  file_to_write = tddium_global_config_file_path
  content ? File.open(file_to_write, 'w') {|f| f.write(content) } : FileUtils.touch(file_to_write)
end

Then /^the tddium global config file should not exist$/ do
  File.should_not exist(tddium_global_config_file_path)
end

Then /^dotfiles should be updated$/ do
  steps %Q{
    And the file ".tddium.mimic" should contain "apikey"
    And the file ".gitignore" should contain ".tddium"
    And the file ".gitignore" should contain ".tddium*"
  }
end

Then /^options should not be saved$/ do
  steps %Q{
    Then the file ".tddium.mimic" should not contain "test_pattern"
    And the file ".tddium.mimic" should not contain "max_parallelism"
    And the file ".tddium.mimic" should not contain "user_data_file"
  }
end
