=begin
Copyright (c) 2011, 2012 Solano Labs All Rights Reserved
=end

require "./lib/tddium/version"

Gem::Specification.new do |s|
  s.name        = "tddium"
  s.version     = Tddium::VERSION
  s.platform    = (RUBY_PLATFORM == 'java' ? RUBY_PLATFORM : Gem::Platform::RUBY)
  s.authors     = ["Solano Labs"]
  s.email       = ["info@tddium.com"]
  s.homepage    = "https://github.com/solanolabs/tddium.git"
  s.summary     = "Run tests in tddium Hosted Test Environment"
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

  s.files         = `git ls-files lib bin`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_runtime_dependency("thor")
  s.add_runtime_dependency("highline")
  s.add_runtime_dependency("json")
  s.add_runtime_dependency("launchy")
  s.add_runtime_dependency("tddium_client", "~> 0.4.2")
  if RUBY_PLATFORM == 'java'
    s.add_runtime_dependency('jruby-openssl')
    s.add_runtime_dependency("msgpack-jruby")
  else
    s.add_runtime_dependency("msgpack", "=0.5.6")
  end

  s.add_development_dependency("aruba", "0.4.6")
  s.add_development_dependency("rdiscount", "1.6.8")
  s.add_development_dependency("pickle")
  s.add_development_dependency("mimic")
  s.add_development_dependency("daemons")
  s.add_development_dependency("httparty", "0.9.0")
  s.add_development_dependency("antilles")
  s.add_development_dependency("rspec")
  s.add_development_dependency("cucumber")
  s.add_development_dependency("fakefs")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("rake")
end
