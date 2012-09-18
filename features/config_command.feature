# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

@mimic
Feature: Config command
  As a Tddium user
  In order to manage non-commited configuration in Tddium
  I want to manage a scoped set of config variables

  Background:
    Given the command is "tddium config"
    And a git repo is initialized on branch "test/foobar"

  Scenario: Display suite config
    Given the user is logged in with a configured suite on branch "test/foobar"
    And the user has the following config:
      | scope     | name      | value     |
      | account   | foo       | bar       |
      | suite     | quz       | blehher   |
    When I run `tddium config`
    Then the output should contain "quz=blehher"
    And the exit status should be 0
    And the output should contain "config:add"

  Scenario: Display account config
    Given the user is logged in with a configured suite on branch "test/foobar"
    And the user has the following config:
      | scope     | name      | value     |
      | account   | foo       | bar       |
      | suite     | quz       | blehher   |
    When I run `tddium config account`
    Then the output should contain "foo=bar"
    And the exit status should be 0
    And the output should contain "config:add"

  Scenario: Handle no keys
    Given the user is logged in with a configured suite on branch "test/foobar"
    And the user has no config
    When I run `tddium config`
    And the exit status should be 0
    And the output should contain "config:add"

  Scenario: Handle API failure
    Given the user is logged in with a configured suite on branch "test/foobar"
    And there is a problem retrieving config
    When I run `tddium config`
    Then the exit status should not be 0
    And the output should contain "API Error"

  Scenario: Fail if the user isn't logged in
    When I run `tddium config`
    Then it should fail with a login hint

  Scenario: Add suite config
    Given the user is logged in with a configured suite on branch "test/foobar"
    And the user has no config
    And setting "third" on the suite will succeed
    When I run `tddium config:add suite third fourth`
    Then the exit status should be 0
    And the output should contain "suite"
    And the output should contain "third=fourth"

  Scenario: Fail to add key if the user isn't logged in
    When I run `tddium config:add suite third fourth`
    Then it should fail with a login hint

  Scenario: Fail to add on API error
    Given the user is logged in with a configured suite on branch "test/foobar"
    But setting "third" on the suite will fail
    When I run `tddium config:add suite third fourth`
    Then the exit status should not be 0
    And the output should contain "API Error"

  Scenario: Remove config successfully
    Given the user is logged in with a configured suite on branch "test/foobar"
    And removing config "default" from the suite will succeed
    When I run `tddium config:remove suite default`
    Then the exit status should be 0
    And the output should contain "Removing config 'default'"
    And the output should contain "Removed config 'default'"

  Scenario: Fail to remove if the user isn't logged in
    When I run `tddium config:remove suite third`
    Then it should fail with a login hint

  Scenario: Fail to remove on API error
    Given the user is logged in with a configured suite on branch "test/foobar"
    But removing config "default" from the suite will fail
    When I run `tddium config:remove suite default`
    Then the exit status should not be 0
    And the output should contain "API Error"
