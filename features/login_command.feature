@mimic
Feature: Login command

  Scenario: Interactively log in successfully
    Given the user can log in and gets API key "apikey"
    When I run `tddium login --environment=mimic` interactively
    And I type "foo@example.com"
    And I type "barbarbar"
    And the console session ends
    Then the output should contain:
    """
    Logged in successfully
    """
    And the exit status should be 0
    And the file ".tddium.mimic" should contain "apikey"
    And the file ".gitignore" should contain ".tddium.mimic"
    And the file ".gitignore" should contain ".tddium-deploy-key.mimic"

  Scenario: Non-interactively log in successfully
    Given the user can log in and gets API key "apikey"
    When I run `tddium login --environment=mimic --email=foo@example.com --password=barbarbar`
    Then the output should contain:
    """
    Logged in successfully
    """
    And the exit status should be 0
    And the file ".tddium.mimic" should contain "apikey"
    And the file ".gitignore" should contain ".tddium.mimic"
    And the file ".gitignore" should contain ".tddium-deploy-key.mimic"

  Scenario: Non-interactively log in unsuccessfully
    Given the user cannot log in
    When I run `tddium login --environment=mimic --email=foo@example.com --password=barbarbar`
    Then the output should contain:
    """
    Access Denied
    """
    And the exit status should be 1
    And the file ".tddium.mimic" should not exist
    And the file ".gitignore" should not exist
