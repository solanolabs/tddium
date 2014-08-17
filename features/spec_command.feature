@mimic
Feature: spec command
  As a tddium user
  In order to run tests
  I want to start a test session

  Background:
    Given the command is "tddium spec"

  Scenario: Fail if user isn't logged in
    Given a git repo is initialized
    When I run `tddium spec`
    Then the exit status should not be 0
    And the output should contain "tddium login"

  @announce-cmd
  Scenario: Fail if user has uncommitted changes
    Given a git repo is initialized
    And the user is logged in
    And the user has a suite for "repo" on "master"
    And the user can create a session
    But the user has uncommitted changes to "foo.rb"
    When I run `tddium spec`
    Then the exit status should not be 0
    And the output should contain "uncommitted"

  Scenario: Use suite on API server but not in local configuration
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in
    And the user has a suite for "repo" on "master"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0

  Scenario: Auto-create a new suite with no .gitignore
    Given the destination repo exists
    And a git repo is initialized on branch "foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a ci-disabled suite named "work/foobar" on branch "foobar"
    And the user creates a suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Disabling automatic CI for this new branch"
    And the output should contain "Creating suite"

  Scenario: Auto-create a new suite for an hg repo
    Given the destination hg repo exists
    And an hg repo is initialized on branch "foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a ci-disabled hg suite named "work/foobar" on branch "foobar"
    And the user creates a suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Disabling automatic CI for this new branch"
    And the output should contain "Creating suite"

  Scenario: Auto-create a new suite with .gitignore
    Given the destination repo exists
    And a git repo is initialized on branch "foobar"
    And a .gitignore file exists in git
    And the user is logged in
    And the user has no suites
    And the user can create a ci-disabled suite named "work/foobar" on branch "foobar"
    And the user creates a suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Creating suite"

  Scenario: Auto-create a new suite with CI enabled
    Given the destination repo exists
    And a git repo is initialized on branch "foobar"
    And a .gitignore file exists in git
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "work/foobar" on branch "foobar"
    And the user creates a suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium run --enable-ci`
    Then the exit status should be 0
    And the output should not contain "Disabling automatic CI for this new branch"
    And the output should contain "Creating suite"

  Scenario: Wait until repo preparation is done
    Given the destination repo exists
    And the SCM ready timeout is 0
    And a git repo is initialized on branch "foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a ci-disabled suite named "work/foobar" on branch "foobar"
    And the user creates a pending suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    And the user can indicate repoman demand
    When I run `tddium spec`
    Then the exit status should be 1
    And the output should contain "Creating suite"
    And the output should contain "prepped"

  Scenario: Display passing result
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite with test_pattern: "spec/foo"
    And the tests start successfully
    And the test all pass
    When I run `tddium spec --max-parallelism=1 --test-pattern=spec/foo`
    Then the exit status should be 0
    And the output should contain "Starting Session"
    And the output should contain "To view results"
    And the output should contain "Final result: passed."
    And options should not be saved

  Scenario: Display test failures
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite with test_pattern: "spec/foo"
    And the tests start successfully
    And the tests all fail
    When I run `tddium spec --max-parallelism=1 --test-pattern=spec/foo`
    Then the exit status should be 1
    And the output should contain "Starting Session"
    And the output should contain "To view results"
    And the output should contain "Final result: failed."
    And the output should contain the list of failed tests
    And options should not be saved

  @announce-cmd
  Scenario: Handle shell globbing
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass
    And an empty file named "spec1.rb" 
    And an empty file named "spec2.rb" 
    When I run `tddium spec spec1.rb spec2.rb`
    Then the exit status should be 0
    And the output should contain "To view results"
    And the output should not contain "emembered"
    And options should not be saved

  Scenario: Output machine readable data with --machine
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass
    And the user can indicate repoman demand
    And the session completes
    When I run `tddium spec --machine`
    Then the exit status should be 0
    And the output should not contain "Ctrl-C"
    And the output should not contain "--->"
    And the output should contain "Final result: passed."

  Scenario: Don't output messages with --machine
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    And the user can indicate repoman demand
    And the session completes
    When I run `tddium spec --machine`
    Then the exit status should be 0
    And the output should not contain "Ctrl-C"
    And the output should not contain "--->"

  Scenario: Output messages in normal mode
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "To view results"
    And the output should contain "Ctrl-C"
    And the output should contain "---> abcdef"
    And the output should not contain "---> abcdef --->"

  Scenario Outline: Update suite settings from repo config file
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :test_pattern:
        - spec/foo_spec.rb
        - features/blah.feature
    """
    And the user can update the suite's test_pattern to "spec/foo_spec.rb,features/blah.feature"
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Updated test pattern"
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |

  Scenario Outline: Update suite settings from repo config file with string values
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      test_pattern:
        - spec/foo_spec.rb
        - features/blah.feature
    """
    And the user can update the suite's test_pattern to "spec/foo_spec.rb,features/blah.feature"
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Updated test pattern"
    Examples:
      | file name  | root section |
      | tddium.yml | tddium:      |
      | tddium.cfg | tddium:      |
      | solano.yml | solano:      |
      | solano.yml |              |

  Scenario Outline: Fail to update suite settings from repo config file
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :test_pattern:
        - spec/foo_spec.rb
    """
    And the user fails to update the suite's test_pattern
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    When I run `tddium spec`
    Then the exit status should be 1
    And the output should not contain "Updated test pattern"
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |
    
  Scenario Outline: Update ruby version from repo config file
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/<file name>" with:
    """
    ---
    <root section>
      :ruby_version: ruby-1.9.3-p0
    """
    And the user can update the suite's ruby_version to "ruby-1.9.3-p0"
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Updated ruby version"
    Examples:
      | file name  | root section |
      | tddium.yml | :tddium:     |
      | tddium.cfg | :tddium:     |
      | solano.yml | :solano:     |
      | solano.yml |              |
