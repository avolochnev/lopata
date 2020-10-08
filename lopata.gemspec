# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "lopata/version"

Gem::Specification.new do |s|
  s.name        = "lopata"
  s.version     = Lopata::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Alexey Volochnev"]
  s.email       = "alexey.volochnev@gmail.com"
  s.homepage    = "https://github.com/avolochnev/lopata"
  s.summary     = "lopata-#{Lopata::Version::STRING}"
  s.description = "Functional acceptance testing"

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += %w[README.md exe/lopata .yardopts]
  s.bindir           = 'exe'
  s.executables      = ['lopata']
  s.test_files       = []
  s.require_path     = "lib"

  s.required_ruby_version = '>= 2.3.0'

  s.add_dependency "httparty", '0.18.1'
  s.add_dependency "thor", '~> 1.0'
  s.add_dependency "rspec-expectations", '~> 3.9'

  s.add_development_dependency "cucumber", "~> 3.1"
  s.add_development_dependency "aruba", "~> 1.0"
end