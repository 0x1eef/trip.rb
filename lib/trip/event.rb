# frozen_string_literal: true

##
# {Trip::Event} represents one of the following
# TracePoint events:
#
#  * `:c_call`:
#     When a method implemented in C is called.
#  * `:c_return`:
#     When a method implemented in C returns.
#  * `:call`:
#     When a method implemented in Ruby is called.
#  * `:return`:
#     When a method implemented in Ruby returns.
#  * `:class`:
#     When a module / class is defined or reopened using the "module"
#     or "class" keywords.
#  * `:end`:
#     When a module / class definition or reopen ends.
#  * `:line`:
#     When on a line that starts an expression or statement.
#  * `:raise`:
#     When an exception is raised.
#  * `:b_call`:
#     When a block is called.
#  * `:b_return`:
#     When a block returns.
#  * `:thread_begin`:
#     When a thread begins.
#  * `:thread_end`:
#     When a thread ends.
#  * `:fiber_switch`:
#     When a Fiber switches context.
#  * `:script_compiled`:
#     When Ruby code is compiled by `eval`, `require`, or `load`.
class Trip::Event
  ##
  # @param [Symbol] name
  #  The name of an event.
  #
  # @param [Hash] tp
  #  A hash from TracePoint.
  def initialize(name, tp)
    @name = name
    @tp = tp
    @since_epoch = Integer(Process.clock_gettime(Process::CLOCK_REALTIME))
  end

  ##
  # @group Event properties
  #
  # @return [Symbol]
  #  Returns the event name.
  def name
    @name
  end

  ##
  # @example
  #  event = trip.resume
  #  time = Time.at(event.since_epoch)
  #
  # @return [Integer]
  #  Returns the event's creation time as a number
  #  of seconds since epoch.
  def since_epoch
    @since_epoch
  end

  ##
  # @return [String]
  #  Returns the path associated with an event.
  def path
    @tp[:path]
  end

  ##
  # @return [Integer]
  #  Returns the line number associated with an event.
  def lineno
    @tp[:lineno]
  end

  ##
  # @return [Object, BasicObject]
  #  Returns the `self` where an event occurred.
  def self
    @tp[:self]
  end

  ##
  # @return [Module]
  #  Returns the module or class associated with an event.
  def module
    event_self = self.self
    ::Module === event_self ? event_self : event_self.class
  end

  ##
  # @return [Symbol]
  #  Returns the method id associated with an event.
  def method_id
    @tp[:method_id]
  end

  ##
  # @return [Binding]
  #  Returns a Binding object bound to where an event occurred.
  def binding
    @tp[:binding]
  end
  # @endgroup

  ##
  # @group Event predicates
  #
  # @return [Boolean]
  #  Returns true when a module / class is opened.
  def module_opened?
    @name == :class
  end

  ##
  # @return [Boolean]
  #  Returns true when a module / class is closed.
  def module_closed?
    @name == :end
  end

  ##
  # @return [Boolean]
  #  Returns true when a block is called.
  def block_call?
    @name == :b_call
  end

  ##
  # @return [Boolean]
  #  Returns true when a block returns.
  def block_return?
    @name == :b_return
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in Ruby is called.
  def rb_call?
    @name == :call
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in Ruby returns.
  def rb_return?
    @name == :return
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in C is called.
  def c_call?
    @name == :c_call
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in C returns.
  def c_return?
    @name == :c_return
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in either Ruby
  #  or C is called.
  def call?
    c_call? || rb_call?
  end

  ##
  # @return [Boolean]
  #  Returns true when a method implemented in either Ruby
  #  or C returns.
  def return?
    c_return? || rb_return?
  end

  ##
  # @return [Boolean]
  #  Returns true when a thread begins.
  def thread_begin?
    @name == :thread_begin
  end

  ##
  # @return [Boolean]
  #  Returns true when a thread ends.
  def thread_end?
    @name == :thread_end
  end

  ##
  # @return [Boolean]
  #  Returns true when an exception is raised.
  def raise?
    @name == :raise
  end

  ##
  # @return [Boolean]
  #  Returns true when starting a new expression or statement.
  def line?
    @name == :line
  end
  # @endgroup

  ##
  # For REPL support.
  #
  # @return [void]
  def pretty_print(q)
    q.text(inspect)
  end

  ##
  # For REPL support.
  #
  # @return [String]
  def inspect
   ["#<",
    to_s.sub!("#<", "").sub!(">", ""),
    " @name=:#{@name}",
    " path='#{path}:#{lineno}'",
    ">"].join
  end

  # @return [Binding]
  #  Returns a binding object for an instance of {Trip::Event}.
  def __binding__
    ::Kernel.binding
  end
end
