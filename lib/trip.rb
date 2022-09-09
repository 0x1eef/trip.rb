# frozen_string_literal: true

##
# Trip is a concurrent tracer that can pause and resume the code
# it is tracing. Trip yields control between two Fibers - typically
# the root Fiber and a Fiber that Trip creates. The process of yielding
# control back and forth between the two Fibers can be repeated until the
# the code being traced has finished and exits normally. Trip is
# currently implemented using [TracePoint](https://www.rubydoc.info/gems/tracepoint/TracePoint).
class Trip
  require_relative "trip/event"
  require_relative "trip/fiber"
  require_relative "trip/version"

  DEFAULT_PAUSE = ->(event) { event.call? || event.return? }
  DEFAULT_EVENTS = %i[call c_call return c_return]
  private_constant :DEFAULT_PAUSE, :DEFAULT_EVENTS

  ##
  # @group Exceptions
  # The superclass of all Trip exceptions.
  Error = Class.new(RuntimeError)

  ##
  # An exception that's raised when the tracer crashes.
  InternalError = Class.new(Error)

  ##
  # An exception that's raised when the {Trip#pause_when Trip#pause_when}
  # callback crashes.
  PauseError = Class.new(Error)
  # @endgroup

  ##
  # @return [<Proc, #call>]
  #  Returns the callable object being traced.
  attr_reader :callable

  ##
  # @return [<Proc, #call>]
  #  Returns the callable that decides when to pause the tracer.
  attr_reader :pauser

  ##
  # @return [<Array<Symbol>, String>]
  #  Returns the events being listened for.
  attr_reader :events

  ##
  # @param [Array<Symbol>] events
  #  An array of event names to listen for.
  #
  # @param [<Proc, #call>] callable
  #  A block, or object that implements "call".
  #
  # @return [Trip]
  #  Returns an instance of Trip.
  def initialize(events = DEFAULT_EVENTS, callable = nil, &block)
    @callable = callable || block
    @fiber = nil
    @pauser = DEFAULT_PAUSE
    @events = events
    if @callable.nil?
      raise ArgumentError, "Expected a block or object implementing 'call'"
    end
  end

  ##
  # Starts the tracer.
  #
  # @raise [Trip::PauseError]
  #  When an exception is raised by the callable given to {Trip#pause_when Trip#pause_when}.
  #
  # @raise [Trip::InternalError]
  #  When Trip encounters an internal error and crashes.
  #
  # @return [Trip::Event, nil]
  #  Returns an event, or nil.
  def start
    @fiber = Trip::Fiber.new(self).spawn
    resume
  end

  ##
  # Starts or resumes the tracer.
  #
  # @raise (see #start)
  # @return [Trip::Event, nil]
  #  Returns an event or nil.
  def resume
    if @fiber.nil?
      start
    else
      e = @fiber.resume
      e == true ? nil : e
    end
  end

  ##
  # Sets a callable that decides when to pause the tracer.
  #
  # @example
  #  trip = Trip.new { Kernel.puts(1 + 1) }
  #  trip.pause_when { |event| event.c_call? || event.c_return? }
  #
  # @param [Proc] callable
  #  A block or object that implements "call".
  #
  # @raise [ArgumentError]
  #  When a **callable** is not provided.
  #
  # @return [void]
  def pause_when(callable = nil, &block)
    callable ||= block
    unless callable.respond_to?(:call)
      raise ArgumentError, "Expected a block or object implementing 'call'"
    end
    @pauser = callable
  end

  ##
  # Performs a trace from start to finish, then returns an array of
  # {Trip::Event Trip::Event} objects upon completion.
  #
  # @return [Array<Trip::Event>]
  #  Returns an array of {Trip::Event Trip::Event} objects.
  def to_a
    events = []
    loop do
      e = resume
      break unless e
      events.push(e)
    end
    events
  end
end
