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
end
