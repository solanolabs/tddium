When /^I respond to "([^"]*)" with "([^"]*)"$/ do |expect, response|
  steps %Q{
    Then the output from "tddium suite" should contain "#{expect}"
    When I type "#{response}"
  }
end
