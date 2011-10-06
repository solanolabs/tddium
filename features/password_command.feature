@mimic
Feature: Password command
  As a Tddium user
  I want to change my password

  Background:
    Given the command is "tddium password"

  Scenario: Fail if user isn't logged in
    When I run `tddium password`
    Then the exit status should not be 0
    And the output should contain "tddium login"
    And the output should contain "tddium heroku"

  Scenario: Successfully change password interactively
    Given the user is logged in
    And the password change succeeds
    When I run `tddium password` interactively
    And I respond to "old password" with "foobar"
    And I respond to "new password" with "foobar3"
    And I respond to "new password" with "foobar3"
    Then the output from "tddium password" should contain "Your password has been changed"
    When the console session ends
    Then the exit status should be 0
    
  Scenario: Old password incorrect
    Given the user is logged in
    And the old password is invalid
    When I run `tddium password` interactively
    And I respond to "old password" with "foobar"
    And I respond to "new password" with "foobar3"
    And I respond to "new password" with "foobar3"
    Then the output from "tddium password" should contain "Current password is invalid"
    When the console session ends
    Then the exit status should not be 0

  Scenario: Confirmation mismatch
    Given the user is logged in
    And the confirmation doesn't match
    When I run `tddium password` interactively
    And I respond to "old password" with "foobar"
    And I respond to "new password" with "foobar3"
    And I respond to "new password" with "foobar2"
    Then the output from "tddium password" should contain "Password doesn't match confirmation"
    When the console session ends
    Then the exit status should not be 0
