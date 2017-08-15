$LOAD_PATH << 'lib'
require 'trip'
Gem::Specification.new do |g|
  g.name        = 'trip'
  g.homepage    = 'https://gitlab.com/0xAB/trip'
  g.authors	= ['1xAB Software']
  g.email       = '0xAB@protonmail.com'
  g.version     = Trip::VERSION
  g.summary     = %q{Provides a concurrent tracer capable of suspending and resuming code as it is being traced.}
  g.description = g.summary
  g.licenses    = ['MIT']
  g.files	= `git ls-files`.split($/)
  g.required_ruby_version = '~> 2.1'
end
