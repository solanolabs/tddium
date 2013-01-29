Given /^the password change succeeds$/ do
  Antilles.install(:put, "/1/users/1/", {:status=>0})
end

Given /^the old password is invalid$/ do
  Antilles.install(:put, "/1/users/1/", {:status=>1, :explanation=>"Current password is invalid"})
end

Given /^the confirmation doesn't match$/ do
  Antilles.install(:put, "/1/users/1/", {:status=>1, :explanation=>"Password doesn't match confirmation"})
end
