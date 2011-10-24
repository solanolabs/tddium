
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

Given /^a git repo is initialized(?: on branch "([^"]*)")?$/ do |branch|
  steps %Q{
    Given a directory named "work"
    And I cd to "work"
    And I successfully run `git init .`
    And a file named "testfile" with:
    """
    some data
    """
    And I successfully run `git config user.email "a@b.com"`
    And I successfully run `git config user.name "A User"`
    And I successfully run `git add .`
    And I successfully run `git commit -am 'testfile'`
  }
  if branch && branch != 'master'
    steps %Q{
    And I successfully run `git checkout -b #{branch}`
    }
  end
end

