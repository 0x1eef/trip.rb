require "trip"

trip = Trip.new(events: %i[class]) do
  class Foo
  end

  class Bar
  end

  class Baz
  end
end

trip.pause_when { |event| event.module_def? }
while event = trip.resume
  print event.self, " class defined", "\n"
end

# == Produces output:
# Foo class defined
# Bar class defined
# Baz class defined
