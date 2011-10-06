@mimic
Feature: Detect upgrade required
  As a Tddium user
  In order to notice when my gem is out of date
  I want the tddium gem to be notified when it needs to be upgraded

  Scenario:  Exit if upgrade is required
    Given the user is logged in
    And my gem is out of date
    When I run `tddium account`
    Then the output should contain "API Error: tddium-preview-0.9.4 is out of date."
    And the exit status should not be 0
