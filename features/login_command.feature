# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: Login command

  Background:
    Given the command is "tddium login"

  Scenario: Interactively log in successfully
    Given the user can log in and gets API key "apikey"
    When I run `tddium login` interactively
    And I type "foo@example.com"
    And I type "barbarbar"
    And the console session ends
    Then the output should contain:
    """
    Logged in successfully
    """
    And the exit status should be 0
    And dotfiles should be updated

  Scenario: Interactively log in successfully without an ssh key
    Given the user can log in and gets API key "apikey" but has no ssh pubkey
    And a file named "ssh_public_key" with:
    """
    ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAkbX/gEl+anbWCMG1qbliaIrI2mcoDk0qPkHFnrlHVCn00zFSY8nHzJoTzkCvBW43iPjagfhHz2mYzChXdbNesf2fxxrvXQbDRrpEyQzw42Iak0OiscomVUkVDyG4J+yR2QH8FiIvx9n2Umow1BLCB/b8socBkyJekMk7NzLf+7/RIOWCgdbj2qY3S8uDNzAVse+lpwkClb+dTLIsy8nYQHnKuG9pLNeTwca5Wu+3+BkgS/Ub6H7m1uaeCxnDz6MiN42uWxwAzWHWd3tZO/cVitTgGpGqDut+E0qbUpg+p8/KNQLYRBb2Mm6DhV4bUVGOJ6/s6bgqr/LjB9WFz4Qjww== moorthi@localhost
    """
    And adding the key "default" will succeed
    When I run `tddium login` interactively
    And I type "foo@example.com"
    And I type "barbarbar"
    And I respond to "ssh key" with "ssh_public_key"
    And the console session ends
    Then the output should contain:
    """
    Logged in successfully
    """
    And the exit status should be 0
    And dotfiles should be updated

  Scenario: Already logged in
    Given the user is logged in
    When I run `tddium login`
    Then the output should contain "already"
    And the exit status should be 0

  Scenario: Non-interactively log in successfully
    Given the user can log in and gets API key "apikey"
    When I run `tddium login --email=foo@example.com --password=barbarbar`
    Then the output should contain:
    """
    Logged in successfully
    """
    And the exit status should be 0
    And dotfiles should be updated

  Scenario: Non-interactively log in unsuccessfully
    Given the user cannot log in
    When I run `tddium login --email=foo@example.com --password=barbarbar`
    Then the output should contain:
    """
    Access Denied
    """
    And the exit status should be 1
    And the file ".tddium.mimic" should not exist
    And the file ".gitignore" should not exist
