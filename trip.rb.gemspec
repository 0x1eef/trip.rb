$LOAD_PATH << "lib"
require "trip"
Gem::Specification.new do |g|
  g.name = "trip.rb"
  g.homepage = "https://github.com/0x1eef/trip.rb"
  g.authors	= ["0x1eef"]
  g.email = "1aab@protonmail.com"
  g.version = Trip::VERSION

  g.summary = <<~SUMMARY
    Trip is a concurrent tracer that can pause, resume and alter code while it is
    being traced. Under the hood, Trip uses `Thread#set_trace_func`.
  SUMMARY

  g.description = <<~DESCRIPTION
    Trip is a concurrent tracer that can pause, resume and alter code while it is
    being traced. Trip yields control between two threads, typically the main thread
    and a thread that Trip creates.

    Under the hood, Trip uses `Thread#set_trace_func` and spawns a new thread
    dedicated to running and tracing a block of Ruby code. Control is yielded
    between the main thread and this new thread until the trace completes.
  DESCRIPTION

  g.licenses = ["MIT"]
  g.files	= `git ls-files`.split($/)
  g.required_ruby_version = ">= 2.0"

  g.add_development_dependency "yard", "~> 0.9"
  g.add_development_dependency "redcarpet", "~> 3.5"
  g.add_development_dependency "rspec", "~> 3.10"
  g.add_development_dependency "standardrb", "~> 1.1"
end
