# frozen_string_literal: true

class Trip
  require 'thread'
  require_relative 'trip/event'
  require_relative 'trip/version'

  Error = Class.new(RuntimeError)
  InternalError = Class.new(Error)
  PauseError = Class.new(Error)
  NotStartedError  = Class.new(Error)
  InProgressError = Class.new(Error)

  # @private
  RUN_STATE   = 'run'

  # @private
  SLEEP_STATE = 'sleep'

  # @private
  END_STATE   = [nil, false]

  # @private
  PAUSE_WHEN  = ->(event) { event.rb_call? || event.rb_return? }

  #
  # @param [Proc] &block
  #   A block of code to trace.
  #
  # @return [Trip]
  #   Returns an instance of Trip, a concurrent tracer.
  #
  def initialize(&block)
    raise ArgumentError, "expected a block" unless block_given?
    @thread = nil
    @block = block
    @queue = nil
    @pause_when = PAUSE_WHEN
    @caller = Thread.current
  end

  #
  # Stores a block that decides when to pause the tracer.
  #
  # @param [Proc] callable
  #   A block or an object that responds to `#call`.
  #
  # @raise [ArgumentError]
  #   When the `callable` param is not given.
  #
  # @return [nil]
  #   Returns nil.
  #
  # @example
  #   trip = Trip.new { Kernel.puts 1+1 }
  #   trip.pause_when {|event| event.c_call? || event.c_return? }
  #   event1 = trip.start
  #   
  def pause_when(callable = nil, &block)
    pauser = callable || block
    raise ArgumentError, "Expected a block or an object that responds to call" unless pauser
    @pause_when = pauser
    nil
  end

  #
  # @return [Boolean]
  #   Returns true when the tracer has started.
  #   (ie {#start} has been called).
  #
  def started?
    @thread != nil
  end

  #
  # @return [Boolean]
  #   Returns true when the tracer thread is running.
  #
  def running?
    @thread and @thread.status == RUN_STATE
  end

  #
  # @return [Boolean]
  #   Returns true when the tracer thread is sleeping.
  #
  def sleeping?
    @thread and @thread.status == SLEEP_STATE
  end

  #
  # @return [Boolean]
  #   Returns true when the tracer thread has finished.
  #
  def finished?
    @thread and END_STATE.include?(@thread.status)
  end

  #
  # Starts the tracer.
  #
  # @raise [Trip::InProgessError]
  #   When there's already a trace in progress that hasn't finished.
  #   This could be raised by calling {#start} twice.
  #
  # @raise [Trip::PauseError]
  #   When an exception is raised by the block given to {#pause_when}.
  #
  # @raise [Trip::InternalError]
  #   When an exception internal to Trip is raised.
  #
  # @return [Trip::Event, nil]
  #   Returns an event, or nil
  #
  def start
    raise InProgressError, "A trace is already in progress." \
                           "Call #resume instead ?" if started? && !finished?
    @queue = Queue.new
    @thread = Thread.new do
      Thread.current.set_trace_func method(:on_event).to_proc
      @block.call
      Thread.current.set_trace_func(nil)
      @queue.enq(nil)
    end
    @queue.deq
  end

  #
  # Resumes the tracer.
  #
  # @raise [Trip::PauseError] (see #start)
  #
  # @raise [Trip::InternalError] (see #start)
  #
  # @raise [Trip::NotStartedError]
  #   When {#start} has not been called.
  #
  # @return [Trip::Event, nil]
  #   Returns an event or nil.
  #
  def resume
    raise NotStartedError, "a trace hasn't started" unless started?
    if sleeping?
      @thread.wakeup
      @queue.deq
    end
  end

  #
  # Stops the tracer.
  #
  # @return [nil]
  #
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
                          file:         file,
                          lineno:       lineno,
                          from_module:  from_module,
                          from_method:  from_method,
                          binding:      binding
                        }
      if event.file != __FILE__ and run_safely(Trip::PauseError.new("The pause Proc encountered an error and crashed")) { @pause_when.call(event) }
        @queue.enq(event)
        Thread.stop
      end
    }
  end

  def run_safely(e)
    yield
  rescue Exception => cause
    e.define_singleton_method(:cause) { cause }
    Thread.current.set_trace_func(nil)
    @caller.raise(e)
    false
  end
end
