# frozen_string_literal: true

class Trip
  require_relative "trip/event"
  require_relative "trip/version"

  RESCUABLE_EXCEPTIONS = [StandardError, ScriptError, SecurityError, SystemStackError]
  DEFAULT_PAUSE = ->(event) { event.call? || event.return? }
  DEFAULT_EVENTS = %i[call c_call return c_return]

  private_constant :RESCUABLE_EXCEPTIONS,
                   :DEFAULT_PAUSE,
                   :DEFAULT_EVENTS

  ##
  # @group Exceptions
  # The superclass of all Trip exceptions.
  Error = Class.new(RuntimeError)

  ##
  # An exception that's raised when the tracer thread crashes.
  InternalError = Class.new(Error)

  ##
  # An exception that's raised when the {Trip#pause_when Trip#pause_when}
  # callback crashes.
  PauseError = Class.new(Error)

  ##
  # An exception that's raised when {Trip#start Trip#start} is called
  # before the current trace has finished.
  # @endgroup
  InProgressError = Class.new(Error)

  ##
  # @param [Proc] block
  #  The block to trace.
  #
  # @param [Array<Symbol>] events
  #  An array of event names to listen for.
  #
  # @return [Trip]
  #  Returns an instance of Trip.
  def initialize(events: DEFAULT_EVENTS, &block)
    raise ArgumentError, "Expected a block to trace" unless block
    @thread = nil
    @tracer = nil
    @block = block
    @queue = nil
    @pause_when = DEFAULT_PAUSE
    @events = events == "*" ? [] : events
    @caller = Thread.current
  end

  ##
  # Starts the tracer.
  #
  # @raise [Trip::InProgessError]
  #  When the tracer has started but hasn't finished.
  #
  # @raise [Trip::PauseError]
  #  When an exception is raised by the callable given to
  #  {#pause_when}.
  #
  # @raise [Trip::InternalError]
  #  When Trip encounters an internal error.
  #
  # @return [Trip::Event, nil]
  #  Returns an event, or nil
  def start
    if started? && !finished?
      raise InProgressError, "A trace is already in progress." \
                             "Call #resume instead ?"
    end
    @queue = Queue.new
    @thread = Thread.new do
      @tracer = TracePoint.new(*@events, &method(:on_event))
      @tracer.enable
      @block.call
      @tracer.disable
      @queue.enq(nil)
    end
    @queue.deq
  end

  ##
  # Starts or resumes the tracer.
  #
  # @raise [Trip::PauseError] (see #start)
  # @raise [Trip::InternalError] (see #start)
  # @return [Trip::Event, nil]
  #  Returns an event or nil.
  def resume
    return start unless started?
    if sleeping?
      @tracer.enable
      @thread.wakeup
      @queue.deq
    end
  end

  ##
  # Stops the tracer.
  #
  # @return [nil]
  def stop
    if @thread
      @tracer.disable
      @thread.exit
      @thread.join
      nil
    end
  end

  ##
  # Sets a callable that decides when to pause the tracer.
  #
  # @param [Proc] callable
  #  A block or an object that implements `#call`.
  #
  # @raise [ArgumentError]
  #  When the *callable* argument is not given.
  #
  # @return [nil]
  #  Returns nil.
  #
  # @example
  #  trip = Trip.new { Kernel.puts 1 + 1 }
  #  trip.pause_when {|event| event.c_call? || event.c_return? }
  #  event = trip.start
  def pause_when(callable = nil, &block)
    callable ||= block
    unless callable.respond_to?(:call)
      raise ArgumentError,
            "Expected a block or an object implementing #call"
    end
    @pause_when = callable
    nil
  end

  ##
  # @return [Boolean]
  #  Returns true when has tracer thread has started.
  def started?
    @thread != nil
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer thread is running.
  def running?
    @thread&.status == "run"
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer thread is sleeping.
  def sleeping?
    @thread&.status == "sleep"
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer thread has exited.
  def finished?
    return false unless @thread
    [nil, false].include?(@thread.status)
  end

  private

  def on_event(tp)
    return if tp.path == __FILE__ ||
              tp.path == "<internal:trace_point>" ||
              @thread != tp.binding.eval("Thread.current")
    rescued_yield(internal_error) do
      event = Event.new(tp.event, copy_tp(tp))
      if rescued_yield(pause_error) { @pause_when.call(event) }
        @queue.enq(event)
        @tracer.disable
        Thread.stop
      end
    end
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

  def copy_tp(tp)
    {
      self: tp.self,
      method_id: tp.method_id,
      binding: tp.binding,
      path: tp.path.dup,
      lineno: tp.lineno
    }
  end

  def rescued_yield(e)
    yield
  rescue *RESCUABLE_EXCEPTIONS => cause
    e.define_singleton_method(:cause) { cause }
    @tracer.disable
    @caller.raise(e)
    false
  end
end
