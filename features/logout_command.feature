# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

@mimic
Feature: Logout Command

  Scenario: Logout successfully
    Given a file named ".tddium.localhost" with:
    """
    {'api_key':'abcdef'}
    """
    And a tddium global config file exists
    When I run `tddium logout --host=localhost` interactively
    And the console session ends
    Then the output should contain:
    """
    Logged out successfully
    """
    And the exit status should be 0
    And the file ".tddium.localhost" should not exist
    And the tddium global config file should not exist
