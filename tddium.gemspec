=begin
Copyright (c) 2011, 2012 Solano Labs All Rights Reserved
=end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tddium/version"

Gem::Specification.new do |s|
  if RUBY_PLATFORM == 'java' then
    s.name        = "tddium-jruby"
  else
    s.name        = "tddium"
  end
  s.version     = Tddium::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Solano Labs"]
  s.email       = ["info@tddium.com"]
  s.homepage    = "https://github.com/solanolabs/tddium.git"
  s.summary     = %q{tddium Hosted Test Environment}
  s.license     = "MIT"
  s.description = <<-EOF
tddium runs your test suite simply and quickly in our managed
cloud environment.  You can run tests by hand, or enable our hosted CI to watch
your git repos automatically.

Tddium automatically and safely parallelizes your tests to save you time, and
takes care of setting up fresh isolated DB instances for each test thread.

Tests have access to a wide variety of databases (postgres, mongo, redis,
mysql, memcache), solr, sphinx, selenium/webdriver browsers, webkit and culerity.

Tddium supports all common Ruby test frameworks, including rspec, cucumber,
test::unit, and spinach.  Tddium also supports Javascript testing using
jasmine, evergreen, and many other frameworks.
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
  s.add_runtime_dependency("github_api")
  s.add_runtime_dependency("tddium_client", "~> 0.4.2")
  if RUBY_PLATFORM == 'java' then
    s.add_runtime_dependency('jruby-openssl')
    s.add_runtime_dependency("msgpack-jruby")
  else
    s.add_runtime_dependency("msgpack", "=0.5.6")
  end

#  s.add_development_dependency("bundler", "~> 1.1.0")
  s.add_development_dependency("rspec")
  s.add_development_dependency("fakefs")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("rake")
  s.add_development_dependency("github_api")
end
