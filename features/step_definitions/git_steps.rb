
Given /^the destination repo exists$/ do
  steps %Q{
    Given a directory named "repo"
    And I cd to "repo"
    And I successfully run `git init --bare .`
    And I cd to ".."
  }
end

Given /^an old version of git is installed$/ do
  pending
end

Given "the git ready timeout is 0" do
  ENV["TDDIUM_GIT_READY_SLEEP"] = "0"
end

Given /^a git repo is initialized(?: on branch "([^"]*)")?$/ do |branch|
  steps %Q{
    Given a directory named "work"
    And I cd to "work"
    And I successfully run `rm -f .gitignore`
    And I successfully run `git init .`
    And a file named "testfile" with:
    """
    some data
    """
    And I successfully run `git config user.email "a@b.com"`
    And I successfully run `git config user.name "A User"`
    And I run `git ls-files --exclude-standard -d -m -t`
    And I successfully run `git add .`
    And I successfully run `git commit -am 'testfile'`
  }
  if branch && branch != 'master'
    steps %Q{
    And I successfully run `git checkout -b #{branch}`
    }
  end
end

Given "a .gitignore file exists in git" do
  steps %{
    Given a file named ".gitignore" with:
    """
    foo
    """
    And I successfully run `git add .gitignore`
    And I successfully run `git commit -am 'add gitignore'`
  }
end

Given /^the user has uncommitted changes to "([^"]+)"$/ do |fn|
  steps %{
    Given a file named "#{fn}" with:
    """
    abc
    """
    And I successfully run `git add #{fn}`
  }
end
