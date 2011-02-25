Feature: tddium Executable
    In order to use tddium
    As a user
    I want to run the tddium command

    Scenario: Running tddium
        When I run "tddium"
        Then it should pass with:
        """
        Usage:

        tddium suite    # Register the suite for this rails app, or manage its settings
        tddium spec     # Run the test suite
        tddium status   # Display information about this suite, and any open dev
                        #   sessions

        tddium login    # Log your unix user in to a tddium account
        tddium logout   # Log out

        tddium account  # View/Manage account information

        tddium dev      # Enter "dev" mode, for single-test quick-turnaround debugging.
        tddium stopdev  # Leave "dev" mode.

        tddium clean    # Clean up test results, especially large objects like videos
        
        tddium help     # Print this usage message
        """
