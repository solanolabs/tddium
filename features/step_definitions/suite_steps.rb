def make_suite_response(name, branch)
  suite = SAMPLE_SUITE_RESPONSE
  suite["repo_name"] = name
  suite["branch"] = branch
  suite["git_repo_uri"] = "file:///#{Dir.tmpdir}/aruba/repo"
  suite
end

Given /^the user has a suite for "([^"]*)" on "([^"]*)"$/ do |name, branch|
  MimicServer.server.install(:get, "/1/suites", {:status=>0, :suites=>[make_suite_response(name, branch)]})
end

Given /^the user has no suites/ do
  MimicServer.server.install(:get, "/1/suites", {:status=>0, :suites=>[]})
end

Given /^the user can create a suite named "([^"]*)" on branch "([^"]*)"$/ do |name, branch|
  MimicServer.server.install(:post, "/1/suites", {:status=>0, :suite=>make_suite_response(name, branch)}, :code=>201)
end

Given /^the destination repo exists$/ do
  steps %Q{
    Given a directory named "repo"
    And I cd to "repo"
    And I successfully run `git init --bare .`
    And I cd to ".."
  }
end

Given /^a git repo is initialized on branch "([^"]*)"$/ do |branch|
  steps %Q{
    Given a directory named "work"
    And I cd to "work"
    And I successfully run `git init .`
    And a file named "testfile" with:
    """
    some data
    """
    And I successfully run `git add .`
    And I successfully run `git commit -am 'testfile'`
    And I successfully run `git checkout -b #{branch}`
  }
end
