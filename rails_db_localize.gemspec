$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_db_localize/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_db_localize"
  s.version     = RailsDbLocalize::VERSION
  s.authors     = [""]
  s.email       = ["yacine@redtonic.net"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RailsDbLocalize."
  s.description = "TODO: Description of RailsDbLocalize."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "faker"
  s.add_development_dependency "better_errors"
  s.add_development_dependency "binding_of_caller"
end
