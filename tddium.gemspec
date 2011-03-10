# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tddium/version"

Gem::Specification.new do |s|
  s.name        = "tddium-preview"
  s.version     = Tddium::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay Moorthi"]
  s.email       = ["info@tddium.com"]
  s.homepage    = "http://www.tddium.com/"
  s.summary     = %q{tddium Cloud Test Runner}
  s.description = %q{tddium gets your rspec+selenium tests into the cloud by running them on your VMs}

  s.rubyforge_project = "tddium"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("thor")
  s.add_runtime_dependency("httparty")
  s.add_runtime_dependency("json")

  s.add_development_dependency("rspec")
  s.add_development_dependency("fakeweb")
  s.add_development_dependency("fakefs")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rack-test")
end
