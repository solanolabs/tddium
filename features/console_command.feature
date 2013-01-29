# Copyright (c) 2012 Solano Labs All Rights Reserved

@mimic
Feature: Console command

  Background:
    Given the command is "tddium console"

  Scenario: Connect to remote console successfully
    Given the user can log in and gets API key "apikey"
    And the user has an active SSH session
    When I run `tddium console 1` interactively
    Then the output should contain:
    """
    Pseudo-terminal will not be allocated because stdin is not a terminal.
    """
    And the exit status should be 255
