require_relative "setup"
require "trip"

module Greeter
  def self.say(message)
    puts message
  end
end

##
# Create a new Trip.
# Pause for events coming from "Greeter.say".
trip = Trip.new { Greeter.say "Hello" }
trip.pause_when { |event| event.module == Greeter && event.method_id == :say }

##
# Start the tracer by calling "Trip#start".
# Afterwards, pause the tracer on the call of
# "Greeter.say". The argument of "Greeter.say",
# `message` is then changed.
event1 = trip.start
print event1.name, " ", event1.method_id, "\n"
print "self: ", event1.self, "\n"
event1.binding.eval("message << ' rubyist!'")

##
# Resume the tracer thread from its paused state,
# and then pauses again for the method return of
# "Greeter.say".
event2 = trip.resume
print event2.name, " ", event2.method_id, "\n"

##
# This call to "trip.resume" returns nil, and
# exits the tracer thread.
event3 = trip.resume
print event3.inspect, "\n"

# == Produces the output:
# call say
# self: Greeter
# Hello rubyist!
# return say
# nil
