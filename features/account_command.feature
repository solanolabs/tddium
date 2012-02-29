# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: Account command
  As a Tddium user
  In order to use Tddium in my organization
  I want to be able to see billing info and control who has access to my account

  Background:
    Given the user has the following memberships in his account:
      | id | role    | email               | display                 |
      | 1  | member  | member@example.com  | [member] member@example.com |
      | 2  | admin   | admin@example.com   | [admin]  admin@example.com  |
      | 3  | owner   | owner@example.com   | [owner]  owner@example.com |
      | 4  | admin   | someone@example.com | [admin]  someone@example.com  |

  Scenario: Display account information
    Given the user is logged in
    And the user has a suite for "alpha" on "master"
    When I run `tddium account`
    Then the output should contain "someone@example.com"
    And the output should contain:
    """
    [member] member@example.com
    [admin]  admin@example.com
    """
    And the output should contain "alpha/master"
    And the output should not contain "Authorize the following SSH"

  Scenario: Display account information with third-party key
    Given the user is logged in with a third-party key
    And the user has a suite for "alpha" on "master"
    When I run `tddium account`
    Then the output should contain "someone@example.com"
    And the output should contain:
    """
    [member] member@example.com
    [admin]  admin@example.com
    """
    And the output should contain "alpha/master"
    And the output should contain "Authorize the following SSH"
    And the ouptut should contain the third party key


  Scenario: Handle API failure
    Given the user is logged in
    And there is a problem retrieving suite information
    When I run `tddium account`
    Then the output should contain "someone@example.com"
    And the output should contain:
    """
    API Error
    """

  Scenario: Fail if user isn't logged in
    When I run `tddium account`
    Then it should fail with a login hint

  Scenario: Add member to account successfully
    Given the user is logged in
    And adding a member to the account will succeed
    When I successfully run `tddium account:add member member2@example.com`
    Then the output should contain "Adding member2@example.com as member..."
    Then the output should contain "Added member2@example.com"

  Scenario: Add member to account unsuccessfully
    Given the user is logged in
    And adding a member to the account will fail with error "add member error"
    When I run `tddium account:add member member@example.com`
    Then the output should not contain "Added member@example.com"
    And the output should contain "add member error"
    And the exit status should not be 0

  Scenario: Fail to add to account when not logged in
    When I run `tddium account:add member member@example.com`
    Then it should fail with:
    """
    tddium must be initialized. Try 'tddium login'
    """

  Scenario: Remove member from account successfully
    Given the user is logged in
    And removing "member@example.com" from the account will succeed
    When I successfully run `tddium account:remove member@example.com`
    Then the output should contain "Removed member@example.com"

  Scenario: Remove member to account unsuccessfully
    Given the user is logged in
    And removing "member@example.com" from the account will fail with error "remove member error"
    When I run `tddium account:remove member@example.com`
    Then the output should not contain "Removed member@example.com"
    And the output should contain "remove member error"
    And the exit status should not be 0

  Scenario: Fail to remove from account when not logged in
    When I run `tddium account:remove member@example.com`
    Then it should fail with:
    """
    tddium must be initialized. Try 'tddium login'
    """
