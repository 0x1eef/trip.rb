require_relative "setup"

class Trip::Math
  def self.add(x, y)
    sum = x + y
    sum.to_s
  end
end

class Trip::Test < Test::Unit::TestCase
  attr_reader :trip

  def setup
    @trip = Trip.new(%i[call return]) { Trip::Math.add(2, 5) }
  end

  def teardown
    trip.to_a
  end
end

class Trip::TripEventTest < Trip::Test
  def test_trip_event_name_is_call
    assert_equal :call, trip.start.name
  end

  def test_trip_event_name_is_return
    trip.start
    assert_equal :return, trip.resume.name
  end

  def test_trip_event_name_is_c_call
    trip.events.replace(%i[c_call c_return])
    assert_equal :c_call, trip.start.name
  end

  def test_trip_event_name_is_c_return
    trip.events.replace(%i[c_call c_return])
    trip.start
    assert_equal :c_return, trip.resume.name
  end

  def test_trip_event_path
    assert_equal __FILE__, trip.start.path
  end

  def test_trip_event_lineno
    assert_equal 4, trip.start.lineno
  end

  def test_trip_event_binding
    b = trip.start.binding
    b.eval("x = 4")
    trip.resume
    assert_equal 9, b.eval("sum")
  end
end
