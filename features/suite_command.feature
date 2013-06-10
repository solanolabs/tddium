# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Background:
    Given the command is "tddium suite"

  Scenario: Fail if the user is not logged in
    Given the destination repo exists
    When I run `tddium suite`
    Then it should fail with a login hint

  Scenario: Fail if CWD isn't in a git repo
    Given the user is logged in
    When I run `tddium suite`
    Then the output should contain "git repo"
    And the exit status should not be 0

  Scenario: Configure a new suite with a complex branch
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "Looks like"
    Then "tddium suite" output should contain "Detected branch test/foobar"
    Then "tddium suite" stderr should not contain "WARNING: Unable to parse"
    When I choose defaults for test pattern, CI settings
    Then "tddium suite" output should contain "Using account 'some_account'"
    Then "tddium suite" output should contain "Created suite"
    When the console session ends
    Then the exit status should be 0

  Scenario: Edit a suite with CLI parameters
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in with a configured suite on branch "test/foobar"
    And the user can update the suite's test_pattern to "spec/foo"
    When I run `tddium suite --edit --test-pattern=spec/foo --non-interactive` 
    Then the output should contain "Updated suite successfully"
    Then the exit status should be 0

  Scenario: Edit a suite's campfire room with CLI parameters
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in with a configured suite on branch "test/foobar"
    And the user can update the suite's campfire_room to "foobar"
    When I run `tddium suite --edit --campfire-room=foobar --non-interactive` 
    Then the output should contain "Updated suite successfully"
    Then the exit status should be 0

  Scenario: Edit a suite's hipchat room with CLI parameters
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in with a configured suite on branch "test/foobar"
    And the user can update the suite's hipchat_room to "foobar"
    When I run `tddium suite --edit --hipchat-room=foobar --non-interactive` 
    Then the output should contain "Updated suite successfully"
    Then the exit status should be 0

  Scenario: Configure a suite with a heroku push target
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in
    And the user has a .tddium for branch "test/foobar"
    And the user has a heroku-push suite for "test" on "test/foobar"
    When I run `tddium suite --name=test --non-interactive`
    Then the output should contain "Heroku"
    And the file ".tddium-deploy-key.mimic" should contain "ssh-rsa"
    Then the exit status should be 0

  Scenario: Belong to mulitple accounts, fail if not provided
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user belongs to two accounts
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "You are a member of these accounts:"
    Then "tddium suite" output should contain "some_account"
    Then "tddium suite" output should contain "another_account"
    When I respond to "account" with ""
    Then "tddium suite" output should contain "You must specify an account"
    When the console session ends
    Then the exit status should be 1

  Scenario: Create a suite under a different account interactively
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user belongs to two accounts
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
    When I run `tddium suite` interactively
    When I respond to "account" with "another_account"
    And I choose defaults for test pattern, CI settings
    Then "tddium suite" output should contain "Using account 'another_account'"
    Then "tddium suite" output should contain "Created suite"
    When the console session ends
    Then the exit status should be 0

  Scenario: Create a suite under a different account with an option
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user belongs to two accounts
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
    When I run `tddium suite --account=another_account --non-interactive`
    Then the output should contain "Using account 'another_account'"
    And the output should contain "Created suite"
    And the exit status should be 0
