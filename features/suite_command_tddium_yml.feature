# Copyright (c) 2011 Solano Labs All Rights Reserved

@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Background:
    Given the command is "tddium suite"

  Scenario: Configure new suite with ruby from tddium.yml
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
       :ruby_version:  ruby-1.9.2-p290-psych
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should contain "Looks like"
    Then the output should contain "Detected branch test/foobar"
    Then the output should contain "Configured ruby ruby-1.9.2-p290-psych from config/tddium.yml"
    Then the output should contain "Created suite..."
    Then the exit status should be 0

  Scenario: Configure new suite with tddium.yml without matching key
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    ---
    :foo:
       :ruby_version:  ruby-1.9.2-p290-psych
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should not contain "Configured ruby ruby-1.9.2-p290-psych from config/tddium.yml"
    Then the output should contain "Detected ruby"
    Then the output should contain "Created suite..."
    Then the exit status should be 0

  Scenario: Configure new suite with empty tddium.yml
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should contain "Looks like"
    Then the output should contain "Detected branch test/foobar"
    Then the output should not contain "Configured ruby ruby-1.9.2-p290-psych from config/tddium.yml"
    Then the output should contain "Detected ruby"
    Then the output should contain "Created suite..."
    Then the output should not contain "Unable to parse"
    Then the exit status should be 0

  Scenario: Non-YAML tddium.yml should generate a warning and then prompt
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
      :test_pattern:
        - spec/controllers/**_spec.rb
        + 
    """
    When I run `tddium suite` interactively
    Then the output from "tddium suite" should contain "Unable to parse"
    Then the output from "tddium suite" should contain "Looks like"
    And I respond to "repo name" with "beta"
    Then the output from "tddium suite" should not contain "Configured ruby ruby-1.9.2-p290-psych from config/tddium.yml"
    Then the output from "tddium suite" should contain "Detected ruby"
    When I choose defaults for test pattern, CI settings
    Then the output from "tddium suite" should contain "Created suite..."
    When the console session ends
    Then the exit status should be 0

  Scenario: Configure new suite with test pattern from tddium.yml
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
      :test_pattern:
        - spec/controllers/**_spec.rb
        - features/api/**.feature
        - test/unit/**_test.rb
    """
    When I run `tddium suite` interactively
    Then the output from "tddium suite" should contain "Looks like"
    And I respond to "repo name" with "beta"
    Then the output from "tddium suite" should contain "Detected branch test/foobar"
    And the output from "tddium suite" should contain "Detected ruby"
    And the output from "tddium suite" should contain "Configured test pattern from config/tddium.yml:"
    And the output from "tddium suite" should contain:
    """
     - spec/controllers/**_spec.rb
     - features/api/**.feature
     - test/unit/**_test.rb
    """
    When I choose defaults for CI settings
    Then the output from "tddium suite" should contain "Created suite..."
    When the console session ends
    Then the exit status should be 0

  Scenario: Exit with error if config/tddium.yml contains the wrong type
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
      :test_pattern:
        :this: is
        :not: a list
    """
    When I run `tddium suite` interactively
    Then the output from "tddium suite" should contain "Looks like"
    And I respond to "repo name" with "beta"
    And the output from "tddium suite" should contain "not properly formatted"
    When the console session ends
    Then the exit status should not be 0
