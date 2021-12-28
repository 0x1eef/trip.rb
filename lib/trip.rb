# frozen_string_literal: true

class Trip
  require_relative "trip/event"
  require_relative "trip/version"

  Error = Class.new(RuntimeError)
  InternalError = Class.new(Error)
  PauseError = Class.new(Error)
  InProgressError = Class.new(Error)

  # @private
  RESCUABLE_EXCEPTIONS = [
    StandardError,
    ScriptError,
    SecurityError,
    SystemStackError
  ]

  # @private
  RUN_STATE = "run"

  # @private
  SLEEP_STATE = "sleep"

  # @private
  END_STATE = [nil, false]

  # The default condition for which to pause the tracer.
  # @private
  DEFAULT_PAUSE_WHEN = ->(event) { event.call? || event.return? }

  # The default events to listen for.
  # @private
  DEFAULT_LISTEN_EVENTS = %i[call c_call return c_return]

  ##
  # @param [Proc] block
  #  A block that will be traced and run on its own thread.
  #
  # @param [Array<Symbol>] events
  #  An array of event names, as Symbols, which the tracer
  #  should listen for.
  #
  # @return [Trip]
  #  Returns an instance of Trip.
  def initialize(events: DEFAULT_LISTEN_EVENTS, &block)
    raise ArgumentError, "Expected a block to trace" unless block
    @thread = nil
    @tracer = nil
    @block = block
    @queue = nil
    @pause_when = DEFAULT_PAUSE_WHEN
    @events = events == :all ? [] : events
    @caller = Thread.current
  end

  ##
  # Starts the tracer.
  #
  # @raise [Trip::InProgessError]
  #  Raised when the tracer has already been started
  #  and hasn't finished tracing.
  #
  # @raise [Trip::PauseError]
  #  Raised when an exception is raised by the callable
  #  given to {#pause_when}.
  #
  # @raise [Trip::InternalError]
  #  Raised when an exception internal to Trip is raised.
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
  # Resumes the tracer - or starts it if the tracer hasn't
  # started yet.
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
  # Stores a callable that decides when to pause the tracer
  # by returning a true or false when called.
  #
  # @param [Proc] callable
  #  A block or an object that implements "call".
  #
  # @raise [ArgumentError]
  #  Raised when the "callable" argument is not provided.
  #
  # @return [nil]
  #  Returns nil.
  #
  # @example
  #  trip = Trip.new { Kernel.puts 1 + 1 }
  #  trip.pause_when {|event| event.c_call? || event.c_return? }
  #  event = trip.start
  def pause_when(callable = nil, &block)
    pauser = callable || block
    raise ArgumentError, "Expected a block or an object implementing #call" unless pauser
    @pause_when = pauser
    nil
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer has started.
  def started?
    @thread != nil
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer thread is running.
  def running?
    @thread and @thread.status == RUN_STATE
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer thread is sleeping.
  def sleeping?
    @thread and @thread.status == SLEEP_STATE
  end

  ##
  # @return [Boolean]
  #  Returns true when the tracer thread has finished.
  def finished?
    @thread and END_STATE.include?(@thread.status)
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
