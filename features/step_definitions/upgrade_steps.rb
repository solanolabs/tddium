Given /^my gem is out of date$/ do
  Antilles.install(:get, "/1/suites", {:status=>1, :explanation=>"tddium-preview-0.9.4 is out of date."}, :code=>426)
end

