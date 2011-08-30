@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Background:
    Given the user is logged in

  Scenario: Configure a new suite
    When I run `tddium suite --environment=mimic` interactively
    And I type "foo"
    And the console session ends
    Then the output should contain:
    """
    ahashdasda
    """
    And the exit status should be 0

