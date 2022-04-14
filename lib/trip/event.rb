# frozen_string_literal: true

##
# {Trip::Event} represents one of the following
# TracePoint events:
#
#  * `:c_call`:
#     When a method implemented in C is called. <br>
#  * `:c_return`:
#     When a method implemented in C returns. <br>
#  * `:call`:
#     When a method implemented in Ruby is called. <br>
#  * `:return`:
#     When a method implemented in Ruby returns. <br>
#  * `:class`:
#     When a module / class is defined or reopened using the "module"
#     or "class" keywords. <br>
#  * `:end`:
#     When a module / class definition or reopening ends. <br>
#  * `:line`:
#     When on a line that starts an expression or statement. <br>
#  * `:raise`:
#     When an exception is raised. <br>
#  * `:b_call`:
#     When a block is called. <br>
#  * `:b_return`:
#     When a block returns. <br>
#  * `:thread_begin`:
#     When a thread begins.<br>
#  * `:thread_end`:
#     When a thread ends.<br>
#  * `:fiber_switch`:
#     When a Fiber switches context. <br>
#  * `:script_compiled`:
#     When Ruby code is compiled by `eval`, `require`, or `load`.
class Trip::Event
  def initialize(name, tp_details)
    @name = name
    @tp_details = tp_details
    @since_epoch = Integer(Process.clock_gettime(Process::CLOCK_REALTIME))
  end

  ##
  # @group Event properties
  #
  # @return [Symbol]
  #  An event name.
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
    @tp_details[:path]
  end

  ##
  # @return [Integer]
  #  Returns the line number associated with an event.
  def lineno
    @tp_details[:lineno]
  end

  ##
  # @return [Object, BasicObject]
  #  Returns the `self` where an event occurred.
  def self
    @tp_details[:self]
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
    @tp_details[:method_id]
  end

  ##
  # @return [Binding]
  #  Returns a Binding object bound to where an event occurred.
  def binding
    @tp_details[:binding]
  end
  # @endgroup

  ##
  # @group Event predicates
  #
  # @return [Boolean]
  #  Returns true when an event is for the definition or
  #  reopening of a module / class.
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
  #  Returns true when an event is a call to a
  #  method implemented in either Ruby or C.
  def call?
    c_call? || rb_call?
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is a return from a
  #  method implemented in either Ruby or C.
  def return?
    c_return? || rb_return?
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is for the raise of
  #  an exception.
  def raise?
    @name == :raise
  end
  # @endgroup # @group Event name predicates

  ##
  # @return [Boolean]
  #  Returns true when an event is for the definition or
  #  reopening of a module / class.
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
  #  Returns true when an event is a call to a
  #  method implemented in either Ruby or C.
  def call?
    c_call? || rb_call?
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is a return from a
  #  method implemented in either Ruby or C.
  def return?
    c_return? || rb_return?
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is for the raise of
  #  an exception.
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
