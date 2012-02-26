# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pan_handler/version"

Gem::Specification.new do |s|
  s.name        = "pan_handler"
  s.version     = PanHandler::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jon Doveston"]
  s.email       = ["jon@doveston.me.uk"]
  s.homepage    = ""
  s.summary     = "Pandoc wrapper"
  s.description = "Uses Pandoc to convert html"

  s.rubyforge_project = "pan_handler"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Development Dependencies
  s.add_development_dependency "rspec", "~> 2.8.0"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "rack-test", ">= 0.5.6"
  s.add_development_dependency "activesupport", ">= 3.0.8"

end
