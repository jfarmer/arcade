$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "arcade/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "arcade"
  s.version     = Arcade::VERSION
  s.authors     = ["Jesse Farmer"]
  s.email       = ["jesse@20bits.com"]
  s.homepage    = "http://github.com/jfarmer/arcade"
  s.summary     = "A Ruby-based DSL for building simple arcade-style games like Pong, etc."
  s.description = <<-EOM
Arcade is a simple Ruby-vased DSL for creating old-school arcade games like Pong.  The philosophy is similar to GameMaker, except expressed as a Ruby library instead of a crazy GUI.
EOM

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_development_dependency "rake"
  s.add_dependency "gosu"
end
