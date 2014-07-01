
Given /^the destination repo exists$/ do
  result = system("mkdir -p #{current_dir} && cd #{current_dir} && mkdir -p repo && cd repo && git init --bare")
  expect(result).to be true
end

Given /^an old version of git is installed$/ do
  pending
end

Given "the SCM ready timeout is 0" do
  ENV["TDDIUM_SCM_READY_SLEEP"] = "0"
end

Given /^a git repo is initialized(?: on branch "([^"]*)")?$/ do |branch|
  cmd = [
    "mkdir -p #{current_dir}",
    "cd #{current_dir}",
    "mkdir -p work",
    "cd work",
    "rm -rf .gitignore",
    "git init .",
    "git remote add origin g@example.com:foo.git",
    "echo 'some data' >> testfile",
    "git config user.email 'a@b.com'",
    "git config user.name 'A User'",
    "git ls-files --exclude-standard -d -m -t",
    "git add .",
    "git commit -am 'testfile'"
  ]
  if branch && branch != 'master'
    cmd << "git checkout -b #{branch}"
  end
  expect(system(cmd.join(" && "))).to be true
  step %{I cd to "work"}
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
