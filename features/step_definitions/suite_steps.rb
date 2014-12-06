# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved
#

require 'bundler'

def make_suite_response(name, branch, options = {})
  suite = SAMPLE_SUITE_RESPONSE.dup
  options.each do |k, v|
    suite[k.to_str] = v if v
  end
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
    suite_response << make_suite_response(repo_name, suite["branch"], suite)
  end
  Antilles.install(:get, "/1/suites/user_suites", {:status=>0, :suites => suite_response})
end

Given /^the user has a suite for "([^"]*)" on "([^"]*)"$/ do |name, branch|
  Antilles.install(:get, "/1/suites/user_suites", {:status=>0, :suites=>[make_suite_response(name, branch)]})
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>make_suite_response(name, branch)})
end

Given /^the user has a heroku-push suite for "([^"]*)" on "([^"]*)"$/ do |name, branch|
  suite = make_suite_response(name, branch)
  suite["ci_enabled"] = true
  suite["ci_pull_url"] = "git@github.com:foo.git"
  suite["ci_push_url"] = "git@heroku.com:foo.git"
  Antilles.install(:get, "/1/suites/user_suites", {:status=>0, :suites=>[suite]})
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>suite})
end

Given /^the user has no suites/ do
  Antilles.install(:get, "/1/suites/user_suites", {:status=>0, :suites=>[]})
end

Given /^the user creates a suite for "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>make_suite_response(name, branch)})
end

Given /^the user creates a pending suite for "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  resp = make_suite_response(name, branch)
  resp["repoman_current"] = false
  Antilles.install(:get, "/1/suites/1", {:status=>0, :suite=>resp})
end

Given /^the user can indicate repoman demand$/ do
  Antilles.install(:post, '/1/accounts/1/demand_repoman', {:status=>0})
end

Given /^there is a problem retrieving suite information$/ do
  Antilles.install(:get, "/1/suites/user_suites", {:status=>1, :explanation=>"Some error"})
end

Given /^the user can create a suite named "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>make_suite_response(name, branch)}, :code=>201)
end

Given /^the user can create a suite named "([^"]*)" on branch "([^"]*)" with bundler "(.*?)"$/ do |name, branch, bundler|
  resp = make_suite_response(name, branch)
  resp["bundler"] = bundler
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>resp}, :code=>201)
end

Given /^the user can create an hg suite named "(.*?)" on branch "(.*?)"$/ do |name, branch|
  resp = make_suite_response(name, branch)
  options = {:code=>201}
  ruby_version = `ruby -v`.strip
  options["params"] = {"suite"=>{"branch"=>"foobar", "scm"=>"hg", "repo_url"=>"ssh://hg@example.com/foo.hg", "repo_name"=>"work", "ruby_version"=>ruby_version, "bundler_version"=>Bundler::VERSION, "rubygems_version"=>Gem::VERSION, "test_pattern"=>"features/**.feature, spec/**_spec.rb, spec/features/**.feature, test/**_test.rb", "ci_pull_url"=> "ssh://hg@example.com/foo.hg", "ci_push_url"=>nil}}
  Antilles.install(:post, "/1/suites", {:status=>0, :suite=>resp}, options)
end

Given /^the user can create a ci\-disabled suite named "(.*?)" on branch "(.*?)"$/ do |name, branch|
  resp = make_suite_response(name, branch)
  options = {:code=>201}
  ruby_version = `ruby -v`.strip
  options["params"] = {"suite"=>{"branch"=>"foobar", "scm"=>"git", "repo_url"=>"g@example.com:foo.git", "repo_name"=>"work", "ruby_version"=>ruby_version, "bundler_version"=>Bundler::VERSION, "rubygems_version"=>Gem::VERSION, "test_pattern"=>"features/**.feature, spec/**_spec.rb, spec/features/**.feature, test/**_test.rb", "ci_pull_url"=>"", "ci_push_url"=>""}}
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

Given /^the suite deletion succeeds for ([0-9]+)$/ do |n|
  Antilles.install(:delete, "/1/suites/#{n}/permanent_destroy", {:status=>0})
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
      id = suite["id"]
      content["branches"][id]["branch"].should == suite["branch"]
    end
  end
end
