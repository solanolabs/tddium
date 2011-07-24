@mimic
Feature: Manage Login

  Scenario: Log in successfully
    Given the user can log in and gets API key "apikey"
    When I run `tddium login --environment=mimic --email=user@example.org --password=password`
    Then the output should contain:
    """
    Logged in successfully
    """
    And the exit status should be 0
    And the file ".tddium.mimic" should contain "apikey"
    And the file ".gitignore" should contain ".tddium.mimic"
    And the file ".gitignore" should contain ".tddium-deploy-key.mimic"
