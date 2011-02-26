When /^I run "tddium (.*)"$/ do |cmd|
  run(unescape("tddium #{cmd}"))
end

