# frozen_string_literal: true
class Trip
  require 'thread'
  require_relative 'trip/event'
  require_relative 'trip/version'

  Error = Class.new(RuntimeError)
  InternalError = Class.new(Error)
  PauseError = Class.new(Error)
  NotStartedError  = Class.new(Error)
  InProgessError = Class.new(Error)

  RUN_STATE   = 'run'
  SLEEP_STATE = 'sleep'
  END_STATE   = [nil, false]
  PAUSE_WHEN  = ->(event) do
    event.rb_call? || event.rb_return?
  end

  #
  #  @param [Proc] &block
  #    A block of code to trace.
  #
  #  @return [Trip]
  #    Returns an instance of Trip, a real time concurrent tracer.
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
  # @param [Proc] callable
  #   A block or an object who responds to `.call`.
  #
  # @return [void]
  #
  def pause_when(callable = nil, &block)
    pauser = callable || block
    raise ArgumentError, "expected a block or an object who responds to call" unless pauser
    @pause_when = pauser
  end

  #
  #  @return [Boolean]
  #    Returns true when a tracer has started.
  #
  def started?
    @thread != nil
  end

  #
  #  @return [Boolean]
  #    Returns true when a tracer is in the process of running code.
  #
  def running?
    @thread and @thread.status == RUN_STATE
  end

  #
  #  @return [Boolean]
  #    Returns true when a tracer has finished tracing.
  #
  def finished?
    @thread and END_STATE.include?(@thread.status)
  end

  #
  #  @return [Boolean]
  #    Returns true when a tracer is idle.
  #
  def sleeping?
    @thread and @thread.status == SLEEP_STATE
  end

  #
  #  @raise [Trip::NotStartedError, Trip::PauseError, Trip::InternalError]
  #  @return [Trip::Event, nil]
  #    Returns an event, or nil
  #
  def start
    raise InProgessError, "a trace is already in progress" if started? and !finished?
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
  #  @raise [Trip::NotStartedError, Trip::PauseError, Trip::InternalError]
  #  @return [Trip::Event, nil]
  #    Returns an event or nil.
  #
  def resume
    raise NotStartedError, "a trace hasn't started" unless started?
    if sleeping?
      @thread.wakeup
      @queue.deq
    end
  end

  #
  #  @return [void]
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
