@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Scenario: Configure a new suite with a complex branch
    Given the destination repo exists
    And a git repo is initialized on branch "test/foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "beta" on branch "test/foobar"
    When I run `tddium suite --environment=mimic` interactively
    And I respond to "repo name" with "beta"
    Then the output from "tddium suite --environment=mimic" should contain "Detected branch test/foobar"
    And I respond to "test pattern" with ""
    And I respond to "URL to pull from" with "disable"
    And I respond to "URL to push to" with "disable"
    And I respond to "Campfire subdomain" with "disable"
    Then the output from "tddium suite --environment=mimic" should contain "Pushing changes to Tddium..."
     And the output from "tddium suite --environment=mimic" should contain "Created suite..."
    When the console session ends
    Then the exit status should be 0

