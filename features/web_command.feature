# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: Web command

  Background:
    Given the command is "tddium web"

  Scenario: Run tddium web
    When I run `tddium web`
    Then the exit status should be 0

  Scenario: Run tddium web with a session ID
    When I run `tddium web 1234`
    Then the exit status should be 0
