# frozen_string_literal: true

##
# The {Trip::Fiber Trip::Fiber} class is responsible for creating
# and controlling an instance of Ruby's [Fiber](https://www.rubydoc.info/stdlib/core/Fiber)
# class that will run and trace a piece of Ruby code. This class is not intended
# to be used directly.
class Trip::Fiber
  require "fiber"

  RESCUABLE_EXCEPTIONS = [
    StandardError, ScriptError,
    SecurityError, SystemStackError
  ]
  private_constant :RESCUABLE_EXCEPTIONS

  ##
  # @param [Trip] trip
  #  An instance of {Trip}.
  #
  # @return  [Trip::Fiber]
  #  Returns an instance of {Trip::Fiber Trip::Fiber}.
  def initialize(trip)
    @trip = trip
    @tracer = nil
    @fiber = nil
  end

  ##
  # Creates a fiber.
  #
  # @return [Trip::Fiber]
  #  Returns an instance of {Trip::Fiber Trip::Fiber}.
  def create
    @fiber = Fiber.new do
      @tracer = TracePoint.new(*events, &method(:receive_event))
      @tracer.enable
      @trip.callable.call
      @tracer.disable
    end
    self
  end

  ##
  # Resumes a fiber.
  #
  # @return [Trip::Event, nil]
  #  Returns an instance of {Trip::Event Trip::Event}, or nil.
  def resume
    @fiber.resume
  rescue FiberError
    nil
  end

  private

  def receive_event(tp)
    return if skip?(tp)
    event = Trip::Event.new(tp.event, {
      self: tp.self, method_id: tp.method_id,
      binding: tp.binding, path: tp.path.dup,
      lineno: tp.lineno
    })
    pause_when(event) and Fiber.yield(event)
  rescue Trip::PauseError => ex
    @tracer.disable
    raise(ex)
  rescue *RESCUABLE_EXCEPTIONS => cause
    @tracer.disable
    raise(internal_error)
  end

  def skip?(tp)
    tp.path == __FILE__ ||
    tp.path == "<internal:trace_point>" ||
    @fiber != Fiber.current
  end

  def internal_error
    Trip::InternalError.new(
      "The tracer encountered an internal error and crashed. " \
      "See #cause for details."
    )
  end

  def pause_error
    Trip::PauseError.new(
      "The pause_when Proc encountered an error and crashed. " \
      "See #cause for details."
    )
  end

  def events
    (@trip.events == "*") ? [] : @trip.events
  end

  def pause_when(event)
    @trip.pauser.call(event)
  rescue *RESCUABLE_EXCEPTIONS => cause
    raise(pause_error)
  end
end
