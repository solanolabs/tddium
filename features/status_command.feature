@mimic
Feature: "tddium status" command
  As a Tddium user
  In order to view my recent sessions
  I want a simple status display

  Background:
    Given the command is "tddium status"

  Scenario: Fail if user isn't logged in
    Given a git repo is initialized
    When I run `tddium status`
    Then the exit status should not be 0
    And the output should contain "tddium login"
