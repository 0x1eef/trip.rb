$LOAD_PATH << 'lib'
require 'trip'
Gem::Specification.new do |g|
  g.name        = 'trip.rb'
  g.homepage    = 'https://github.com/rg-8/trip.rb'
  g.authors	= ['0x1eef']
  g.email       = '0x1eef@protonmail.com'
  g.version     = Trip::VERSION
  g.summary     = <<-S
Trip is a concurrent tracer that can pause, resume and alter code while it is
being traced. Under the hood, Trip uses `Thread#set_trace_func`.
S
  g.description = g.summary
  g.licenses    = ['MIT']
  g.files	= `git ls-files`.split($/)
  g.required_ruby_version = '~> 2.0'
end
