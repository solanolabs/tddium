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
    ssh: connect to host localhost port 22: Connection refused
    """
    And the exit status should be 255
