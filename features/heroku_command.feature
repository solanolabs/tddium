@mimic 
Feature: "tddium heroku" command
  As a user of the tddium Heroku addon
  In order to use Tddium without signing up again
  I want to link my heroku account with Tddium

  Background:
    Given the user has the following memberships in his account:
      | id | role    | email               | display                 |
      | 1  | member  | member@example.com  | [member] member@example.com |
      | 2  | admin   | admin@example.com   | [admin]  admin@example.com  |
      | 3  | owner   | owner@example.com   | [owner]  owner@example.com |
      | 4  | admin   | someone@example.com | [admin]  someone@example.com  |
    And the command is "tddium heroku"

  Scenario: Configure Heroku account successfully
    Given the user has configured the Heroku add-on
    And a git repo is initialized
    And the user has no suites
    And the user has no keys
    And a file named "ssh_public_key" with:
    """
    ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAkbX/gEl+anbWCMG1qbliaIrI2mcoDk0qPkHFnrlHVCn00zFSY8nHzJoTzkCvBW43iPjagfhHz2mYzChXdbNesf2fxxrvXQbDRrpEyQzw42Iak0OiscomVUkVDyG4J+yR2QH8FiIvx9n2Umow1BLCB/b8socBkyJekMk7NzLf+7/RIOWCgdbj2qY3S8uDNzAVse+lpwkClb+dTLIsy8nYQHnKuG9pLNeTwca5Wu+3+BkgS/Ub6H7m1uaeCxnDz6MiN42uWxwAzWHWd3tZO/cVitTgGpGqDut+E0qbUpg+p8/KNQLYRBb2Mm6DhV4bUVGOJ6/s6bgqr/LjB9WFz4Qjww== moorthi@localhost
    """
    And adding the key "default" will succeed
    When I run `tddium heroku` interactively
    And I respond to "Enter password" with "barbarbar"
    And I respond to "Confirm your password" with "barbarbar"
    And I respond to "ssh key" with "ssh_public_key"
    And I respond to "continue:" with "I AGREE"
    And the console session ends
    Then the output should contain:
    """
    Thanks for installing the Tddium Heroku Add-On!
    """
    And the output should contain "tddium run"
    And the exit status should be 0
    And dotfiles should be updated

  Scenario: Error running Heroku command
    Given the user has configured the Heroku add-on
    But the heroku command fails
    When I run `tddium heroku`
    Then the exit status should not be 0
    And the output should contain:
    """
    didn't recognize
    """

  Scenario: Show current user if already logged in
    Given a git repo is initialized
    And the user is logged in
    And the user has no suites
    And the user has the following keys:
      | name      |
      | default   |
    When I run `tddium heroku`
    Then the output should contain "Username:"
    And the exit status should be 0

  Scenario: Warn if heroku gem not installed
    Given the user has configured the Heroku add-on
    But the heroku command is not found
    When I run `tddium heroku`
    Then the exit status should not be 0
    And the output should contain:
    """
    command not found
    """

  Scenario: Fail if Heroku config contains unrecognized API key
    Given the user a heroku config with an invalid API key
    When I run `tddium heroku`
    Then the exit status should not be 0
    And the output should contain:
    """
    Unrecognized user
    """

  @wip
  Scenario: Require terms of service

  @wip
  Scenario: Handle activation failed
