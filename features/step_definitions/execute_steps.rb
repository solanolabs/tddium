When /^I run tddium "([^"]*)"$/ do |cmd|
  run_simple(unescape("bin/tddium #{cmd}"), false)
end

