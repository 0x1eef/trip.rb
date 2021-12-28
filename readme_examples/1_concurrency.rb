require "trip"

##
# Create a new Trip.
# Pause for all events originating from "Kernel.puts".
trip = Trip.new { Kernel.puts 1 + 1 }
trip.pause_when { |event| event.module == Kernel && event.method_id == :puts }

##
# Start the tracer by spawning a new thread,
# which is then paused (suspended) upon the
# method call of "Kernel.puts"
event1 = trip.start
print event1.name, " ", event1.method_id, "\n"

##
# Resume the tracer thread from its paused state,
# and then pause again for the method return of
# "Kernel.puts".
event2 = trip.resume
print event2.name, " ", event2.method_id, "\n"

##
# This call to "trip.resume" returns nil, and
# exits the tracer thread.
event3 = trip.resume
print event3.inspect, "\n"

# == Produces the output:
# c_call puts
# 2
# c_return puts
# nil
