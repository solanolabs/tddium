# Copyright (c) 2011-2014 Solano Labs All Rights Reserved

@mimic
Feature: suite command
  As a user
  In order to interact with Tddium
  I want to configure a test suite

  Background:
    Given the command is "tddium suite"

  Scenario Outline: Configure new suite with ruby from repo config file
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
       :ruby_version:  ruby-1.9.2-p290-psych
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should contain "Looks like"
    Then the output should contain "Detected branch test/foobar"
    Then the output should contain "Configured ruby ruby-1.9.2-p290-psych from config/<file name>"
    Then the output should contain "Created suite"
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario Outline: Configure new suite with bundler from repo config file
    Given the user is logged in, and can successfully create a new suite in a git repo with bundler '1.3.5'
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :bundler_version:  '1.3.5'
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should contain "Looks like"
    Then the output should contain "Detected branch test/foobar"
    Then the output should contain "Configured bundler version 1.3.5 from config/<file name>"
    Then the output should contain "Created suite"
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario Outline: Configure new suite with repo config file without matching key
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
       :ruby_version:  ruby-1.9.2-p290-psych
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should not contain "Configured ruby ruby-1.9.2-p290-psych from config/<file name>"
    Then the output should contain "Detected ruby"
    Then the output should contain "Created suite"
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :foo:        |
      | tddium.cfg | :foo:        |

  Scenario Outline: Configure new suite with empty repo config file
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    """
    When I run `tddium suite --name=beta --ci-pull-url=disable --ci-push-url=disable --test-pattern=spec/*`
    Then the output should contain "Looks like"
    Then the output should contain "Detected branch test/foobar"
    Then the output should not contain "Configured ruby ruby-1.9.2-p290-psych from config/<file name>"
    Then the output should contain "Detected ruby"
    Then the output should contain "Created suite"
    Then the output should not contain "Unable to parse"
    Then the exit status should be 0
    Examples:
      | file name  |
      | tddium.yml |
      | tddium.cfg |
      | solano.yml |

  Scenario Outline: Non-YAML repo config file should generate a warning and then prompt
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :test_pattern:
        - spec/controllers/**_spec.rb
        + 
    """
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "Unable to parse"
    Then "tddium suite" output should contain "Looks like"
    Then "tddium suite" output should not contain "Configured ruby ruby-1.9.2-p290-psych from config/<file name>"
    Then "tddium suite" output should contain "Detected ruby"
    When I choose defaults for test pattern, CI settings
    Then "tddium suite" output should contain "Created suite"
    When the console session ends
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario Outline: Configure new suite with test pattern from repo config file
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :test_pattern:
        - spec/controllers/**_spec.rb
        - features/api/**.feature
        - test/unit/**_test.rb
    """
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "Looks like"
    Then "tddium suite" output should contain "Detected branch test/foobar"
    And "tddium suite" output should contain "Detected ruby"
    And "tddium suite" output should contain "Configured test pattern from config/<file name>:"
    And "tddium suite" output should contain:
    """
     - spec/controllers/**_spec.rb
     - features/api/**.feature
     - test/unit/**_test.rb
    """
    When I choose defaults for CI settings
    Then "tddium suite" output should contain "Created suite"
    When the console session ends
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario Outline: Configure new suite with test exclude pattern from repo config file
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :test_pattern:
        - spec/controllers/**_spec.rb
        - features/api/**.feature
        - test/unit/**_test.rb
      :test_exclude_pattern:
        - test/unit/skip_test.rb
    """
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "Looks like"
    Then "tddium suite" output should contain "Detected branch test/foobar"
    And "tddium suite" output should contain "Detected ruby"
    And "tddium suite" output should contain "Configured test pattern from config/<file name>:"
    And "tddium suite" output should contain "Configured test exclude pattern from config/<file name>:"
    And "tddium suite" output should contain:
    """
     - spec/controllers/**_spec.rb
     - features/api/**.feature
     - test/unit/**_test.rb
    """
    And "tddium suite" output should contain:
    """
     - test/unit/skip_test.rb
    """
    When I choose defaults for CI settings
    Then "tddium suite" output should contain "Created suite"
    When the console session ends
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario Outline: Configure new suite with test exclude pattern and string values in repo config file
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      test_pattern:
        - spec/controllers/**_spec.rb
        - features/api/**.feature
        - test/unit/**_test.rb
      test_exclude_pattern:
        - test/unit/skip_test.rb
    """
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "Looks like"
    Then "tddium suite" output should contain "Detected branch test/foobar"
    And "tddium suite" output should contain "Detected ruby"
    And "tddium suite" output should contain "Configured test pattern from config/<file name>:"
    And "tddium suite" output should contain "Configured test exclude pattern from config/<file name>:"
    And "tddium suite" output should contain:
    """
     - spec/controllers/**_spec.rb
     - features/api/**.feature
     - test/unit/**_test.rb
    """
    And "tddium suite" output should contain:
    """
     - test/unit/skip_test.rb
    """
    When I choose defaults for CI settings
    Then "tddium suite" output should contain "Created suite"
    When the console session ends
    Then the exit status should be 0
    Examples:
      | file name  | root section |
      | tddium.yml | tddium:      |
      | tddium.cfg | tddium:      |
      | solano.yml | solano:      |
      | solano.yml |              |

  Scenario Outline: Exit with error if repo config file contains the wrong type
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :test_pattern:
        :this: is
        :not: a list
    """
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "Looks like"
    And "tddium suite" output should contain "not properly formatted"
    When the console session ends
    Then the exit status should not be 0
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario: Exit with error if tddium.yml and solano.yml concurrently exist
    Given the user is logged in, and can successfully create a new suite in a git repo
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
      :ruby_version:  ruby-1.9.2-p290-psych
    """
    And a file named "config/solano.yml" with:
    """
    ---
    :ruby_version:  ruby-1.9.2-p290-psych
    """
    When I run `tddium suite` interactively
    Then "tddium suite" output should contain "You have both solano.yml and tddium.yml in your repo"
    When the console session ends
    Then the exit status should not be 0
