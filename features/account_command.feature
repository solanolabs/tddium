# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

@mimic
Feature: Account command
  As a Tddium user
  In order to use Tddium in my organization
  I want to be able to see billing info and control who has access to my account

  Background:
    Given the user has the following memberships in his account:
      | id | account_id  | role    | user_handle  | user_email          |
      | 1  | 1           | admin   | member       | member@example.com  |
      | 2  | 1           | admin   | admin        | admin@example.com   |
      | 3  | 1           | owner   | owner        | owner@example.com   |
      | 4  | 1           | admin   | someone      | someone@example.com |

  Scenario: Display account information
    Given the user is logged in
    And the user has a suite for "alpha" on "master"
    When I run `tddium account`
    Then the output should contain "someone@example.com"
    And the output should contain "member   member@example.com   admin"
    And the output should contain "admin    admin@example.com    admin"
    And the output should contain "owner    owner@example.com    owner"
    And the output should contain "someone  someone@example.com  admin"
    And the output should contain "alpha  master  git@github.com:user/repo.git"
    And the output should not contain "Authorize the following SSH"

  Scenario: Display account information for two accounts
    Given the user belongs to two accounts
    And the user is logged in
    And the user has a suite for "alpha" on "master"
    When I run `tddium account`
    Then the output should contain "someone@example.com"
    And the output should contain "Organization: some_account"
    And the output should contain "Organization: another_account"

  Scenario: Display account information with third-party key
    Given the user is logged in with a third-party key
    And the user has a suite for "alpha" on "master"
    When I run `tddium account`
    Then the output should contain "someone@example.com"
    And the output should contain "member   member@example.com   admin"
    And the output should contain "admin    admin@example.com    admin"
    And the output should contain "owner    owner@example.com    owner"
    And the output should contain "someone  someone@example.com  admin"
    And the output should contain "alpha  master  git@github.com:user/repo.git"
    And the output should contain "Authorize the following SSH"
    And the ouptut should contain the third party key

  Scenario: Handle API failure
    Given the user is logged in
    And there is a problem retrieving suite information
    When I run `tddium account`
    And the output should contain:
    """
    API Error
    """

  Scenario: Fail if user isn't logged in
    When I run `tddium account`
    Then it should fail with a login hint

  Scenario: Fail if the user is logged into multiple accounts
    Given the user is logged in to multiple accounts
    When I run `tddium account`
    Then it should fail with "Your .tddium file has an invalid API key."

  Scenario: Display account info if the .tddium files match
    Given the user is logged in to a single account
    And the user has no suites
    When I run `tddium account`
    Then the output should contain "someone@example.com"

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
    Solano CI must be initialized. Try 'tddium login'
    """

  Scenario: Remove member from account successfully
    Given the user is logged in
    And removing "member@example.com" from the account will succeed
    When I successfully run `tddium account:remove member@example.com`
    Then the output should contain "Removed member@example.com"

  Scenario: Remove member from account unsuccessfully
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
    Solano CI must be initialized. Try 'tddium login'
    """
