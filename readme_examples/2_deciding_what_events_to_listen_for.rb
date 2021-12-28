require "trip"

def add(x,y)
  Kernel.puts x + y
end

##
# Create a new Trip.
# The events listened for are scoped to call
# and return events from Ruby methods (excludes C methods)
trip = Trip.new(events: %i[call return]) { add(20,50) }
while event = trip.resume
  print event.name, " ", event.method_id, "\n"
end

# == Produces the output:
# call add
# 70
# return add