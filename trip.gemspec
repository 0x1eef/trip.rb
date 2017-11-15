$LOAD_PATH << 'lib'
require 'trip'
Gem::Specification.new do |g|
  g.name        = 'trip.rb'
  g.homepage    = 'https://gitlab.com/0xAB/trip'
  g.authors	= ['1xAB Software']
  g.email       = '1xAB@protonmail.com'
  g.version     = Trip::VERSION
  g.summary     = "Provides a concurrent tracer"
  g.description = "Provides a concurrent tracer capable of suspending and resuming code as it is being traced. It yields control between two threads, usually the main thread and a thread that Trip creates."
  g.description = g.summary
  g.licenses    = ['MIT']
  g.files	= `git ls-files`.split($/)
  g.required_ruby_version = '~> 2.0'
end
