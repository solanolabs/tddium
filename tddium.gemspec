=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tddium/version"

Gem::Specification.new do |s|
  s.name        = "tddium"
  s.version     = TddiumVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Solano Labs"]
  s.email       = ["info@tddium.com"]
  s.homepage    = "http://www.tddium.com/"
  s.summary     = %q{tddium Hosted Ruby Testing}
  s.description = <<-EOF
tddium runs your rspec, cucumber, and test::unit tests in our managed
cloud environment.  You can run tests by hand, or enable our hosted CI to watch
your git repos automatically.

Tddium parallelizes your tests to save you time, and takes care of setting up
fresh isolated DB instances for each test thread.

Tests have access to a wide variety of databases (postgres, mongo, redis,
mysql, memcache), solr, sphinx, selenium/webdriver browsers, webkit and culerity.
EOF

  s.rubyforge_project = "tddium"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("thor")
  s.add_runtime_dependency("highline")
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("launchy")
  s.add_runtime_dependency("tddium_client", "~> 0.2.0")
  s.add_runtime_dependency("bundler", "~> 1.1.0")

  s.add_development_dependency("rspec")
  s.add_development_dependency("fakefs")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("rake")
end
