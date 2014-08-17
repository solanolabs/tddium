# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

Given /^the destination hg repo exists$/ do
  result = system("mkdir -p #{current_dir} && cd #{current_dir} && mkdir -p repo && cd repo && hg init .")
  expect(result).to be true
end

Given /^an hg repo is initialized(?: on branch "([^"]*)")?$/ do |branch|
  url = "ssh://hg@example.com/foo.hg"
  cmd = [
    "mkdir -p #{current_dir}",
    "cd #{current_dir}",
    "mkdir -p work",
    "cd work",
    "rm -rf .hgignore",
    "rm -rf .hg",
    "hg init .",
    "echo '[ui]\\nusername = A User <a@b.com>\\n\\n[paths]\\ndefault = #{url}\\ndefault-push = #{url}' > .hg/hgrc",
    "echo 'some data' >> testfile",
    "hg status -mardu",
    "hg add .",
    "hg commit -m 'testfile'"
  ]
  if branch && branch != 'default'
    cmd << "hg branch #{branch}"
    cmd << "hg commit -m 'branch #{branch}'"
  end
  expect(system(cmd.join(" && "))).to be true
  step %{I cd to "work"}
end

Given "a .hgignore file exists in hg" do
  steps %{
    Given a file named ".hgignore" with:
    """
    foo
    """
    And I successfully run `hg add .hgignore`
    And I successfully run `hg commit -m 'add hgignore'`
  }
end

Given /^the user has uncommitted hg changes to "([^"]+)"$/ do |fn|
  steps %{
    Given a file named "#{fn}" with:
    """
    abc
    """
    And I successfully run `hg add #{fn}`
  }
end
