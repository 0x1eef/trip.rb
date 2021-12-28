require "trip"

trip = Trip.new { Kernel.puts 1 + 1 }
trip.pause_when { |event| event.module == Kernel && event.method_id == :puts }

# Start the tracer.
# A new thread is spawned, and the code is then run
# and quickly suspended for the method call of "puts".
event1 = trip.start
print event1.name, " ", event1.method_id, "\n"

# Resume the suspended tracer thread.
# The last event is for the method return of "puts"
event2 = trip.resume
print event2.name, " ", event2.method_id, "\n"

# Resume the tracer thread for the last time,
# and finish the trace. Last event is "nil".
event3 = trip.resume
print event3.inspect, "\n"

# == Produces the output:
# c_call puts
# 2
# c_return puts
# nil
