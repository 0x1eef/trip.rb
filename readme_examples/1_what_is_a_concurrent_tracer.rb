# frozen_string_literal: true

require_relative "setup"
require "trip"

module Stdout
  def self.write(message)
    puts(message)
  end
end

##
# Create a new Trip.
# Pause for events coming from "Stdout.write".
trip = Trip.new { Stdout.write("Ruby is".dup) }
trip.pause_when { |event| event.self == Stdout && event.method_id == :write }

##
# Enter "Stdout.write" - then mutate a local
# variable while the tracer thread is paused.
event = trip.start
event.binding.eval("message << ' cool.'")

##
# Execute the "puts message" line, and pause
# for the return of "Stdout.write".
event = trip.resume

##
# Exit the "Stdout.write" method, and the
# tracer thread.
event = trip.resume

##
# Ruby is cool.
