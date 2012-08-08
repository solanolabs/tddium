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
    And the output should contain "tddium heroku"

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
    And the user can create a suite named "work/foobar" on branch "foobar"
    And the user creates a suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Creating suite"

  Scenario: Auto-create a new suite with .gitignore
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
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "Creating suite"

  Scenario: Wait until repo preparation is done
    Given the destination repo exists
    And the git ready timeout is 0
    And a git repo is initialized on branch "foobar"
    And the user is logged in
    And the user has no suites
    And the user can create a suite named "work/foobar" on branch "foobar"
    And the user creates a pending suite for "work/foobar" on branch "foobar"
    And the user can create a session
    And the user successfully registers tests for the suite 
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 1
    And the output should contain "Creating suite"
    And the output should contain "prepped"

  Scenario: Don't remember test pattern or max-parallelism
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
    And options should not be saved

  Scenario: Ignore remembered test pattern and max-parallelism
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite and remembered options
    And the user can create a session
    And the user successfully registers tests for the suite with test_pattern: default
    And the tests start successfully
    And the test all pass
    When I run `tddium spec`
    Then the exit status should be 0
    And the output should contain "To view results"
    And the output should not contain "emembered"
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
    And the session completes
    When I run `tddium spec --machine`
    Then the exit status should be 0
    And the output should not contain "Ctrl-C"
    And the output should not contain "--->"
    And the output should contain:
      """
      %%%% TDDIUM CI DATA BEGIN %%%%
      --- 
      :session_id: 1
      %%%% TDDIUM CI DATA END %%%%
      """

  Scenario: Don't output messages with --machine
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with messages
    And the session completes
    When I run `tddium spec --machine`
    Then the exit status should be 0
    And the output should not contain "Ctrl-C"
    And the output should not contain "--->"
    And the output should contain:
      """
      %%%% TDDIUM CI DATA BEGIN %%%%
      --- 
      :session_id: 1
      %%%% TDDIUM CI DATA END %%%%
      """

  Scenario: Output trailing warnings with --machine
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And the user can create a session
    And the user successfully registers tests for the suite
    And the tests start successfully
    And the test all pass with a warning message
    And the session completes
    When I run `tddium spec --machine`
    Then the exit status should be 0
    And the output should not contain "Ctrl-C"
    And the output should not contain "--->"
    And the output should contain:
      """
      Warnings:
      """

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
    And the output should not contain:
      """
      %%%% TDDIUM CI DATA BEGIN %%%%
      --- 
      :session_id: 1
      %%%% TDDIUM CI DATA END %%%%
      """

  Scenario: Update suite settings from tddium.yml
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
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
    
  Scenario: Fail to update suite settings from tddium.yml
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
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
    
  Scenario: Update ruby version from tddium.yml
    Given the destination repo exists
    And a git repo is initialized
    And the user is logged in with a configured suite
    And a file named "config/tddium.yml" with:
    """
    ---
    :tddium:
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
    
