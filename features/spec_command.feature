@mimic
Feature: spec command
  As a tddium user
  In order to run tests
  I want to start a test session

  Background:
    Given the command is "tddium spec"

  Scenario: Fail if user isn't logged in
    Given a git repo is initialized
    When I run `tddium spec`
    Then the exit status should not be 0
    And the output should contain "tddium login"
    And the output should contain "tddium heroku"
