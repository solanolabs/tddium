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

  Scenario: Output machine readable data
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass
    When I run `tddium spec --machine`
    Then the exit status should be 0
    And the output should not contain "Ctrl-C"
    And the output should contain:
      """
      %%%% TDDIUM CI DATA BEGIN %%%%
      --- 
      :session_id: 1
      %%%% TDDIUM CI DATA END %%%%
      """

  Scenario: Don't output machine readable data
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Test report"
    And the output should contain "Ctrl-C"
    And the output should not contain:
      """
      %%%% TDDIUM CI DATA BEGIN %%%%
      --- 
      :session_id: 1
      %%%% TDDIUM CI DATA END %%%%
      """
