Given /^the user is logged in$/ do
  @api_key = "abcdef"
  steps %Q{
    Given a file named ".tddium.mimic" with:
    """
    {"api_key":"#{@api_key}"}
    """
  }
end
