# frozen_string_literal: true

class Trip::Event < BasicObject
  ##
  # Returns one of the following event names:
  #
  #  * <code>:c_call</code>
  #  * <code>:c_return</code>
  #  * <code>:call</code>
  #  * <code>:return</code>
  #  * <code>:class</code>
  #  * <code>:end</code>
  #  * <code>:line</code>
  #  * <code>:raise</code>
  #  * <code>:b_call</code>
  #  * <code>:b_return</code>
  #  * <code>:thread_begin</code>
  #  * <code>:thread_end</code>
  #  * <code>:fiber_switch</code>
  #  * <code>:script_compiled</code>
  #
  # @see https://docs.w3cub.com/ruby~3/tracepoint#class-TracePoint-label-Events
  #
  # @return [Symbol]
  #  An event name.
  attr_reader :name

  ##
  # @return [Integer]
  #  Number of seconds since epoch.
  attr_reader :created_at

  def initialize(name, tp_details)
    @name = name
    @tp_details = tp_details
    @created_at = ::Process.clock_gettime(::Process::CLOCK_REALTIME)
  end

  ##
  # @return [String]
  #  Returns the path where an event occurred.
  def path
    @tp_details[:path]
  end

  ##
  # @return [Integer]
  #  Returns the line number where an event occurred.
  def lineno
    @tp_details[:lineno]
  end

  ##
  # @return [Object, BasicObject]
  #  Returns the value of self in the context of where
  #  an event occurred.
  def self
    @tp_details[:self]
  end

  ##
  # @return [Module]
  #  Returns the Module in the context of where an
  #  event occurred.
  def module
    event_self = self.self
    ::Module === event_self ? event_self : event_self.class
  end

  ##
  # @return [Symbol]
  #  Returns the ID (name) of the method where an event
  #  occurred.
  def method_id
    @tp_details[:method_id]
  end

  ##
  # @return [Boolean]
  #  Returns true when the event is for the definition of
  #  a class or module using "class Name" or "module Name"
  #  syntax.
  def module_def?
    name == :class
  end

  ##
  # @return [Binding]
  #  Returns a Binding object in the context of where
  #  an event occurred.
  def binding
    @tp_details[:binding]
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is a call from a
  #  method implemented in Ruby.
  def rb_call?
    @name == :call
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is a return from a
  #  method implemented in Ruby.
  def rb_return?
    @name == :return
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is a call to a method
  #  implemented in C.
  def c_call?
    @name == :c_call
  end

  ##
  # @return [Boolean]
  #  Returns true when an event is a return from a
  #  method implemented in C.
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

  # @return [String]
  def inspect
    "#<Trip::Event:0x#{__id__.to_s(16)} " \
    "name='#{name}' " \
    "path='#{path}' lineno='#{lineno}' " \
    "self='#{self.self}' method_id='#{method_id}' " \
    "binding=#{binding.inspect}>"
  end

  # @return [Binding]
  #  Returns a binding object for an instance of {Trip::Event}.
  def __binding__
    ::Kernel.binding
  end
end
