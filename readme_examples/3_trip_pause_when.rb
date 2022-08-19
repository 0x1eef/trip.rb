require_relative "setup"
require "trip"

trip = Trip.new(events: %i[class]) do
  class Foo
  end

  class Bar
  end

  class Baz
  end
end

trip.pause_when(&:module_opened?)
while event = trip.resume
  print event.self, " class opened", "\n"
end

##
# Foo class opened
# Bar class opened
# Baz class opened
