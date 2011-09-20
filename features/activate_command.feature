@mimic
Feature: Activate command
  As a Tddium user
  In order to use an invitation code
  I want to activate my account and upload an ssh key

  Background:
    Given the command is "tddium activate"

  Scenario:  Try to activate when logged in
    Given the user is logged in
    When I run `tddium activate`
    Then the exit status should not be 0
    And the output should contain "You are logged in."

  Scenario: Activate for the first time
    Given "abcdef" is a valid invitation token
    And a file named "ssh_public_key" with:
    """
    ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAkbX/gEl+anbWCMG1qbliaIrI2mcoDk0qPkHFnrlHVCn00zFSY8nHzJoTzkCvBW43iPjagfhHz2mYzChXdbNesf2fxxrvXQbDRrpEyQzw42Iak0OiscomVUkVDyG4J+yR2QH8FiIvx9n2Umow1BLCB/b8socBkyJekMk7NzLf+7/RIOWCgdbj2qY3S8uDNzAVse+lpwkClb+dTLIsy8nYQHnKuG9pLNeTwca5Wu+3+BkgS/Ub6H7m1uaeCxnDz6MiN42uWxwAzWHWd3tZO/cVitTgGpGqDut+E0qbUpg+p8/KNQLYRBb2Mm6DhV4bUVGOJ6/s6bgqr/LjB9WFz4Qjww== moorthi@localhost
    """
    When I run `tddium activate` interactively
    And I respond to "token" with "abcdef"
    And I respond to "Enter password" with "password"
    And I respond to "Confirm your password" with "password"
    And I respond to "Enter your ssh key" with "ssh_public_key"
    And I respond to "accept the license" with "I AGREE"
    Then the output from "tddium activate" should contain "Creating account"
    When the console session ends
    Then the exit status should be 0
