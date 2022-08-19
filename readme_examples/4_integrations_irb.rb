require_relative "setup"
require "trip"

module Stdout
  def self.write(message)
    putzzz(message)
  end
end

trip = Trip.new(events: %i[raise]) { Stdout.write("hello") }
trip.pause_when(&:raise?)
event = trip.start
event.binding.irb
