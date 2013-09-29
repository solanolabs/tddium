# Copyright (c) 2013 Solano Labs All Rights Reserved

@mimic
Feature: Web command

  Background:
    Given the command is "tddium status"

  Scenario: Run tddium status
    When I run `tddium status --argument=bogus`
    Then the exit status should be 1

  Scenario: Run tddium status with a session ID
    When I run `tddium status --argument=bogus 1234`
    Then the exit status should be 1
