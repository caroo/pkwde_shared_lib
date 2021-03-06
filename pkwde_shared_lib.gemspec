# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pkwde_shared_lib/version"

Gem::Specification.new do |s|
  s.name        = "pkwde_shared_lib"
  s.version     = PkwdeSharedLib::VERSION
  s.authors     = ["pkw.de dev team"]
  s.email       = ["dev@pkw.de"]
  s.homepage    = ""
  s.summary     = %q{Collects all of the stuff we use in each service}
  s.description = %q{Includes: capistrano recipes, god definitions, github/pivotaltracker project integration, background jobs scheduler interface, continious integration tasks, git hooks}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency "capistrano", ">= 2.6.0"
  s.add_dependency "capistrano-ext", ">= 1.2.1"
  s.add_dependency "tins", ">= 0.3.0"
  s.add_dependency "rake", ">= 0.8.7"
  s.add_dependency "json", ">= 1.4.6"
  
  s.add_development_dependency "test-unit", ">= 2.3.0"
  s.add_development_dependency "mocha", ">= 0.9.12"
end
