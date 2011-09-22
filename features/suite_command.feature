@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Background:
    Given the command is "tddium suite"

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

  Scenario: Configure new suite with ruby from tddium.yml
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
       :ruby_version:  ruby-1.9.2-p290-psych
    """
    When I run `tddium suite` interactively
    Then the output from "tddium suite" should contain "Looks like"
    And I respond to "repo name" with "beta"
    Then the output from "tddium suite" should contain "Detected branch test/foobar"
    Then the output from "tddium suite" should contain "Configured ruby ruby-1.9.2-p290-psych from tddium.yml"
    When I choose defaults for test pattern, CI and campfire settings
    Then the output from "tddium suite" should contain "Created suite..."
    When the console session ends
    Then the exit status should be 0



