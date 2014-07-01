# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

def empty_config_for_account_2
  Antilles.install(:get, "/1/accounts/#{SAMPLE_ACCOUNT_ID_2}/env",
                   {:status=>0, :env=>{}})
end

Given /^the user has the following config:$/ do |table|
  empty_config_for_account_2
  table.hashes.each do |row|
    sc = row[:scope]
    Antilles.install(:get, "/1/#{sc}s/#{eval("SAMPLE_#{sc.upcase}_ID")}/env",
                     {:status=>0, :env=>{row[:name]=>row[:value]}})
  end
end

Given /^the user has no config$/ do
  empty_config_for_account_2
  %w{account repo suite}.each do |sc|
    Antilles.install(:get, "/1/#{sc}s/#{eval("SAMPLE_#{sc.upcase}_ID")}/env",
                     {:status=>0, :env=>{}})
  end
end

Given /^there is a problem retrieving config$/ do
  empty_config_for_account_2
  %w{account repo suite}.each do |sc|
    Antilles.install(:get, "/1/#{sc}s/#{eval("SAMPLE_#{sc.upcase}_ID")}/env",
                     {:status=>1, :explanation=>"ERROR"},
                     :code=>409)
  end
end

capture_scope="(suite|repo|account)"

Given /^setting "([^"]*)" on the #{capture_scope} will succeed$/ do |arg1, scope|
  Antilles.install(:post, "/1/#{scope}s/#{eval("SAMPLE_#{scope.upcase}_ID")}/env",
                   {:status=>0})
end

Given /^setting "([^"]*)" on the #{capture_scope} will fail$/ do |arg1, scope|
  Antilles.install(:post, "/1/#{scope}s/#{eval("SAMPLE_#{scope.upcase}_ID")}/env",
                   {:status=>1, :explanation=>"error"},
                   :code=>409)
end

Given /^removing config "([^"]*)" from the #{capture_scope} will succeed$/ do |arg1, scope|
  Antilles.install(:delete, "/1/#{scope}s/#{eval("SAMPLE_#{scope.upcase}_ID")}/env/#{arg1}",
                   {:status=>0})
end

Given /^removing config "([^"]*)" from the #{capture_scope} will fail$/ do |arg1, scope|
  Antilles.install(:delete, "/1/#{scope}s/#{eval("SAMPLE_#{scope.upcase}_ID")}/env/#{arg1}",
                   {:status=>1, :explanation=>"error"}, :code=>409)
end
