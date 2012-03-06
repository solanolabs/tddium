# Copyright (c) 2011 Solano Labs All Rights Reserved

def make_suite_response(name, branch)
  suite = SAMPLE_SUITE_RESPONSE
  suite["repo_name"] = name
  suite["branch"] = branch
  suite["git_repo_uri"] = "file:///#{Dir.tmpdir}/tddium-aruba/repo"
  suite["repoman_current"] = true
  suite
end

Given /^the user has a suite for "([^"]*)" on "([^"]*)"$/ do |name, branch|
  Antilles.install(:get, "/1/suites", {:status=>0, :suites=>[make_suite_response(name, branch)]})
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>make_suite_response(name, branch)})
end

Given /^the user has no suites/ do
  Antilles.install(:get, "/1/suites", {:status=>0, :suites=>[]})
end

Given /^there is a problem retrieving suite information$/ do
  Antilles.install(:get, "/1/suites", {:status=>1, :explanation=>"Some error"})
end

Given /^the user can create a suite named "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>make_suite_response(name, branch)}, :code=>201)
end

Given /^the user can update the suite's test_pattern to "([^"]*)"$/ do |pattern|
  options = {}
  options["params"] = {"test_pattern"=>pattern}
  Antilles.install(:put, "/1/suites/1", {:status=>0}, options)
end

Given /^the user can update the suite's ruby_version to "([^"]*)"$/ do |ruby_version|
  options = {}
  options["params"] = {"ruby_version"=>ruby_version}
  Antilles.install(:put, "/1/suites/1", {:status=>0}, options)
end

Given /^the user fails to update the suite's test_pattern$/ do
  Antilles.install(:put, "/1/suites/1", {:status=>1, :explanation=>"Some error"})
end

Given /^I choose defaults for test pattern, CI settings$/ do
  steps %Q{
    And I respond to "test pattern" with ""
    And I choose defaults for CI settings
  }
end

Given /^I choose defaults for CI settings$/ do
  steps %Q{
    And I respond to "URL to pull from" with "disable"
    And I respond to "URL to push to" with "disable"
  }
end


Given /^the user is logged in, and can successfully create a new suite in a git repo$/ do
  steps %Q{
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
  }
end
