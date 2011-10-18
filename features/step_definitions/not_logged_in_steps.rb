Then /it should fail with a login hint/ do
  steps %Q{
    Then the exit status should not be 0
    And the output should contain "tddium login"
    And the output should contain "tddium heroku"
  }
end
