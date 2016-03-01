# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "lopata/rspec/version"

Gem::Specification.new do |s|
  s.name        = "lopata"
  s.version     = Lopata::RSpec::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Alexey Volochnev"]
  s.email       = "alexey.volochnev@gmail.com"
  # s.homepage    = "http://github.com/avolochnev/lopata"
  s.summary     = "lopata-#{Lopata::RSpec::Version::STRING}"
  s.description = "Functional acceptance tesging with rspec"

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += %w[README.md exe/lopata]
  s.executables      = `git ls-files -- exe/*`.split("\n").map{ |f| File.basename(f) }
  s.test_files       = []

  s.required_ruby_version = '>= 2.1.0'

  s.add_dependency "httparty"
  s.add_dependency "thor"
end