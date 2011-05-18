# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "city_hash/version"

Gem::Specification.new do |s|
  s.name        = "city_hash"
  s.version     = CityHash::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ashwin Ramaswamy"]
  s.email       = ["ashwin.raman9@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{CityHash for Ruby}
  s.description = %q{Google's CityHash Implementation in Ruby}

  s.rubyforge_project = "city_hash"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency('test-unit')
  s.add_development_dependency('rubyzip')
end
