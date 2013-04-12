# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

def make_suite_response(name, branch, options = {})
  suite = SAMPLE_SUITE_RESPONSE.dup
  suite["id"] = options[:id] if options[:id]
  suite["repo_name"] = name
  suite["branch"] = branch
  suite["git_repo_uri"] = "file:///#{Dir.tmpdir}/tddium-aruba/repo"
  suite["repoman_current"] = true
  suite["ci_ssh_pubkey"] = "ssh-rsa ABCDEFGG"
  suite
end

Given /^the user has the following suites for the repo named "([^"]*)":$/ do |repo_name, table|
  suite_data = table.hashes
  suite_response = []
  suite_data.each do |suite|
    suite_response << make_suite_response(repo_name, suite["branch"], :id => suite["id"])
  end
  Antilles.install(:get, "/1/suites", {:status=>0, :suites => suite_response})
end

Given /^the user has a suite for "([^"]*)" on "([^"]*)"$/ do |name, branch|
  Antilles.install(:get, "/1/suites", {:status=>0, :suites=>[make_suite_response(name, branch)]})
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>make_suite_response(name, branch)})
end

Given /^the user has a heroku-push suite for "([^"]*)" on "([^"]*)"$/ do |name, branch|
  suite = make_suite_response(name, branch)
  suite["ci_enabled"] = true
  suite["ci_pull_url"] = "git@github.com:foo.git"
  suite["ci_push_url"] = "git@heroku.com:foo.git"
  Antilles.install(:get, "/1/suites", {:status=>0, :suites=>[suite]})
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>suite})
end

Given /^the user has no suites/ do
  Antilles.install(:get, "/1/suites", {:status=>0, :suites=>[]})
end

Given /^the user creates a suite for "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>make_suite_response(name, branch)})
end

Given /^the user creates a pending suite for "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  resp = make_suite_response(name, branch)
  resp["repoman_current"] = false
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>resp})
end

Given /^there is a problem retrieving suite information$/ do
  Antilles.install(:get, "/1/suites", {:status=>1, :explanation=>"Some error"})
end

Given /^the user can create a suite named "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>make_suite_response(name, branch)}, :code=>201)
end

Given /^the user can create a suite named "([^"]*)" on branch "([^"]*)" with bundler "(.*?)"$/ do |name, branch, bundler|
  resp = make_suite_response(name, branch)
  resp["bundler"] = bundler
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>resp}, :code=>201)
end

Given /^the user can create a ci\-disabled suite named "(.*?)" on branch "(.*?)"$/ do |name, branch|
  resp = make_suite_response(name, branch)
  options = {:code=>201}
  options["params"] = {"suite"=>{"branch"=>"foobar", "repo_url"=>"g@example.com:foo.git", "repo_name"=>"work", "ruby_version"=>"ruby 1.9.2p290 (2011-07-09 revision 32553) [x86_64-linux]", "bundler_version"=>"Bundler version 1.2.1", "rubygems_version"=>"1.8.24", "test_pattern"=>"features/**.feature, spec/**_spec.rb, spec/features/**.feature, test/**_test.rb", "ci_pull_url"=>"", "ci_push_url"=>""}}
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>resp}, options)
end

Given /^the user can update the suite's (.*?) to "([^"]*)"$/ do |field, value|
  options = {}
  options["params"] = {field=>value}
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

Given /^the user is logged in, and can successfully create a new suite in a git repo with bundler "([^"]*)"$/ do |bundler|
  steps %Q{
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar" with "#{bundler}"
  }
end

Then /^the file "([^"]*)" should contain the following branches:$/ do |file, table|
  prep_for_fs_check do
    content = JSON.parse(IO.read(file))
    suite_data = table.hashes
    suite_data.each do |suite|
      branch = suite["branch"]
      content["branches"][branch]["id"].should == suite["id"]
    end
  end
end
