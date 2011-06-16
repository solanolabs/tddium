=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tddium/version"

Gem::Specification.new do |s|
  s.name        = "tddium-preview"
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

Tests run in parallel to save you time, and, if you use Rails, tddium takes care
of setting up fresh isolated DB instances for each test instance.

Tests can access a limited set of private Selenium RC servers.
EOF

  s.rubyforge_project = "tddium"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("thor")
  s.add_runtime_dependency("highline")
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("tddium_client", ">=0.0.6")
  s.add_runtime_dependency("bundler")

  s.add_development_dependency("rspec")
  s.add_development_dependency("fakefs")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("rake")
end
