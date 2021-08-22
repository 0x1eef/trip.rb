# frozen_string_literal: true

class Trip
  require_relative "trip/event"
  require_relative "trip/version"

  Error = Class.new(RuntimeError)
  InternalError = Class.new(Error)
  PauseError = Class.new(Error)
  NotStartedError = Class.new(Error)
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

  # @private
  PAUSE_WHEN = ->(event) { event.rb_call? || event.rb_return? }

  # @param [Proc] &block
  #  The block to be traced.
  #
  # @return [Trip]
  #  Returns an instance of Trip.
  def initialize(&block)
    raise ArgumentError, "Expected a block to trace" unless block
    @thread = nil
    @block = block
    @queue = nil
    @pause_when = PAUSE_WHEN
    @caller = Thread.current
  end

  # Stores a callable that decides when to pause the tracer.
  #
  # @param [Proc] callable
  #  A block or an object that responds to "#call".
  #
  # @raise [ArgumentError]
  #  Raised when the "callable"  argument is not provided.
  #
  # @return [nil]
  #  Returns nil.
  #
  # @example
  #  trip = Trip.new { Kernel.puts 1+1 }
  #  trip.pause_when {|event| event.c_call? || event.c_return? }
  #  event = trip.start
  def pause_when(callable = nil, &block)
    pauser = callable || block
    raise ArgumentError, "Expected a block or an object implementing #call" unless pauser
    @pause_when = pauser
    nil
  end

  # @return [Boolean]
  #  Returns true when a trace has been started
  def started?
    @thread != nil
  end

  # @return [Boolean]
  #  Returns true when the tracer thread is running.
  def running?
    @thread and @thread.status == RUN_STATE
  end

  # @return [Boolean]
  #  Returns true when the tracer thread is sleeping.
  def sleeping?
    @thread and @thread.status == SLEEP_STATE
  end

  # @return [Boolean]
  #  Returns true when the tracer thread has finished.
  def finished?
    @thread and END_STATE.include?(@thread.status)
  end

  # Starts the tracer.
  #
  # @raise [Trip::InProgessError]
  #  Raised when there is already a trace in progress.
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
      Thread.current.set_trace_func method(:on_event).to_proc
      @block.call
      Thread.current.set_trace_func(nil)
      @queue.enq(nil)
    end
    @queue.deq
  end

  # Resumes the tracer.
  #
  # @raise [Trip::PauseError] (see #start)
  #
  # @raise [Trip::InternalError] (see #start)
  #
  # @raise [Trip::NotStartedError]
  #  Raised when {#start} has not been called.
  #
  # @return [Trip::Event, nil]
  #  Returns an event or nil.
  def resume
    raise NotStartedError, "A trace must be started first" unless started?
    if sleeping?
      @thread.wakeup
      @queue.deq
    end
  end

  # Stops the tracer.
  #
  # @return [nil]
  def stop
    if @thread
      @thread.set_trace_func(nil)
      @thread.exit
      @thread.join
      nil
    end
  end

  private

  def on_event(type, file, lineno, from_method, binding, from_module)
    run_safely(Trip::InternalError.new("The tracer encountered an internal error and crashed")) {
      event = Event.new type, {
        file: file,
        lineno: lineno,
        from_module: from_module,
        from_method: from_method,
        binding: binding
      }
      if (event.file != __FILE__) && run_safely(Trip::PauseError.new("The pause Proc encountered an error and crashed")) { @pause_when.call(event) }
        @queue.enq(event)
        Thread.stop
      end
    }
  end

  def run_safely(e)
    yield
  rescue *RESCUABLE_EXCEPTIONS => cause
    e.define_singleton_method(:cause) { cause }
    Thread.current.set_trace_func(nil)
    @caller.raise(e)
    false
  end
end
