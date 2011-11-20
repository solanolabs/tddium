# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: Keys command
  As a Tddium user
  In order to use Tddium from multiple computers/logins
  I want to manage a list of SSH keys authorized to use Tddium

  Background:
    Given `tddium keys` will write into tmp storage

  Scenario: Display keys
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    When I run `tddium keys`
    Then the output should contain "default"
    And the exit status should be 0
    And the output should contain "another"
    And the output should contain "keys:add"

  Scenario: Handle API failure
    Given the user is logged in
    And there is a problem retrieving keys
    When I run `tddium keys`
    Then the exit status should not be 0
    And the output should contain "API Error"

  Scenario: Fail if the user isn't logged in
    When I run `tddium keys`
    Then it should fail with a login hint

  Scenario: Add key successfully
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    And adding the key "third" will succeed
    When I run `tddium keys:add third`
    Then the exit status should be 0
    And the key file named "third" should exist
    And the output should contain "Generating"
    And the output should contain "authorized"
    And the output should contain "Hostname"

  Scenario: Fail to add key if the user isn't logged in
    When I run `tddium keys:add third`
    Then it should fail with a login hint

  Scenario: Fail to add key with duplicate name
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    When I run `tddium keys:add another`
    Then the exit status should not be 0
    And the key file named "another" should not exist
    And the output should contain "already have"

  Scenario: Fail to generate key that already exists in the filesystem
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    And adding the key "third" will succeed
    But the key file named "third" exists
    When I run `tddium keys:add third`
    Then the exit status should not be 0
    And the output should contain "already exists"

  Scenario: Fail to add on API error
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    But adding the key "third" will fail
    When I run `tddium keys:add third`
    Then the exit status should not be 0
    And the output should contain "API Error"


  Scenario: Remove key successfully
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    And removing the key "default" will succeed
    When I run `tddium keys:remove default`
    Then the exit status should be 0
    And the output should contain "Removing key 'default'"
    And the output should contain "Removed key 'default'"

  Scenario: Fail to remove if the user isn't logged in
    When I run `tddium keys:remove third`
    Then it should fail with a login hint

  Scenario: Fail to remove on API error
    Given the user is logged in
    And the user has the following keys:
      | name      |
      | default   |
      | another   |
    And removing the key "default" will fail
    When I run `tddium keys:remove default`
    Then the exit status should not be 0
    And the output should contain "API Error"


