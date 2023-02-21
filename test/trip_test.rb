# frozen_string_literal: true

require_relative "setup"

class Trip::Planet
  def initialize(name)
    @name = name
  end

  def echo(message)
    message
  end
end

class Trip::Test < Test::Unit::TestCase
  attr_reader :trip

  def setup
    @trip = Trip.new(%i[call return]) { Trip::Planet.new("earth").echo("ping") }
  end

  def teardown
    trip.to_a
  end
end

class Trip::TripTest < Trip::Test
  def test_new_with_no_arguments
    assert_raises(ArgumentError) { Trip.new }
  end
end

class Trip::TripStartTest < Trip::Test
  def test_start_returns_event
    assert_instance_of Trip::Event, trip.start
  end

  def test_start_returns_nil
    trip.pause_when { false }
    assert_equal nil, trip.start
  end
end

class Trip::PauseWhenTest < Trip::Test
  def test_pause_when_with_no_arguments
    assert_raises(ArgumentError) { trip.pause_when }
  end

  def test_pause_when_with_block
    blk = proc {}
    trip.pause_when(&blk)
    assert_equal blk, trip.pauser
  end

  def test_pause_when_with_callable
    callable = proc {}
    trip.pause_when(callable)
    assert_equal callable, trip.pauser
  end

  def test_pause_when_with_exception
    trip.pause_when { raise }
    assert_raises(Trip::PauseError) { trip.start }
  end

  def test_pause_when_with_exceptions_cause
    trip.pause_when { raise "from test" }
    trip.start
  rescue Trip::PauseError => ex
    assert_equal "from test", ex.cause.message
  end
end
