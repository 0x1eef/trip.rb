# frozen_string_literal: true

$LOAD_PATH << "lib"
require "trip"
Gem::Specification.new do |g|
  g.name = "trip.rb"
  g.homepage = "https://github.com/0x1eef/trip.rb#readme"
  g.authors = ["0x1eef"]
  g.email = "0x1eef@protonmail.com"
  g.version = Trip::VERSION
  g.summary = "A concurrent tracer that can pause and resume the code it is tracing."
  g.description = g.summary
  g.licenses = ["0BSD"]
  g.files	= `git ls-files`.split($/)
  g.required_ruby_version = ">= 2.0"

  g.add_development_dependency "test-unit", "~> 3.5.7"
  g.add_development_dependency "yard", "~> 0.9"
  g.add_development_dependency "redcarpet", "~> 3.5"
  g.add_development_dependency "standardrb", "~> 1.0"
end
