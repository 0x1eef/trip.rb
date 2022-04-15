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
  #  time = Time.at(event.since_epoch)
  #  # ..
  #
  # @return [Integer]
  #  Returns the event's creation time as a number of seconds
  #  since epoch.
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
  # @group Event name predicates
  #
  # @return [Boolean]
  #  Returns true for the definition or reopen of a module / class.
  def module_def?
    name == :class
  end

  ##
  # @return [Boolean]
  #  Returns true for a call to a method implemented in Ruby.
  def rb_call?
    @name == :call
  end

  ##
  # @return [Boolean]
  #  Returns true for a return from a method implemented in Ruby.
  def rb_return?
    @name == :return
  end

  ##
  # @return [Boolean]
  #  Returns true for a call to a method implemented in C.
  def c_call?
    @name == :c_call
  end

  ##
  # @return [Boolean]
  #  Returns true for a return from a method implemented in C.
  def c_return?
    @name == :c_return
  end

  ##
  # @return [Boolean]
  #  Returns true for a call to a method implemented in either
  #  Ruby or C.
  def call?
    c_call? || rb_call?
  end

  ##
  # @return [Boolean]
  #  Returns true for a return from a method implemented in either
  #  Ruby or C.
  def return?
    c_return? || rb_return?
  end

  ##
  # @return [Boolean]
  #  Returns true for the raise of an exception.
  def raise?
    @name == :raise
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
