require_relative "setup"
require "trip"

def add(x, y)
  puts(x + y)
end

trip = Trip.new(events: %i[call return]) { add(20, 50) }
while event = trip.resume
  print event.name, " ", event.method_id, "\n"
end

##
# call add
# 70
# return add
