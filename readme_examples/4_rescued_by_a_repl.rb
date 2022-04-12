require "trip"

module Greeter
  def self.say(message)
    putzzz message
  end
end

trip = Trip.new(events: %i[raise]) { Greeter.say("hello") }
trip.pause_when { |event| event.raise? }
event = trip.start
event.binding.irb
