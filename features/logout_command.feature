# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: Logout Command

  Scenario: Logout successfully
    Given a file named ".tddium.mimic" with:
    """
    {'api_key':'abcdef'}
    """
    When I run `tddium logout --environment=mimic` interactively
    And the console session ends
    Then the output should contain:
    """
    Logged out successfully
    """
    And the exit status should be 0
    And the file ".tddium.mimic" should not exist
