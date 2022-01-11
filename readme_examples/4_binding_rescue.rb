require "trip"

class Person
  def initialize(name: )
    @name = name
  end

  def greet
    putzzz "Hello"
  end
end

trip = Trip.new(events: %i[raise]) { Person.new(name: "0x1eef").greet }
trip.pause_when { |event| event.raise? }
event = trip.start
event.binding.irb
