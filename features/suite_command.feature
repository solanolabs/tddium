# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Background:
    Given the command is "tddium suite"

  Scenario: Fail if the user is not logged in
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
    Then the output from "tddium suite" should contain "Looks like"
    And I respond to "repo name" with "beta"
    Then the output from "tddium suite" should contain "Detected branch test/foobar"
    When I choose defaults for test pattern, CI and campfire settings
    Then the output from "tddium suite" should contain "Created suite..."
    When the console session ends
    Then the exit status should be 0

