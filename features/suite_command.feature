@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Scenario: Configure a new suite
    Given the destination repo exists
    And a git repo is initialized on branch "test"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test"
    When I run `tddium suite --environment=mimic` interactively
    Then the output from "tddium suite --environment=mimic" should contain "repo name"
    When I type "beta"
    When I type ""
    When I type "disable"
    And I type "disable"
    And I type "disable"
    And the console session ends
    Then the exit status should be 0

