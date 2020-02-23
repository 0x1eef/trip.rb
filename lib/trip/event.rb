# frozen_string_literal: true
class Trip::Event < BasicObject
  #
  # @return [String]
  #   Returns the type of event as reported by the `Thread#set_trace_func` API
  #   (eg "c-call", "call", "c-return", "return", ...),
  #
  attr_reader :type

  #
  # @api private
  #
  def initialize(type, event)
    @type = type
    @event = event
  end

  #
  # @return [String]
  #   Returns the path to a file where an event occurred.
  #
  def file
    @event[:file]
  end

  #
  # @return [Integer]
  #   Returns the line number where an event occurred,
  #
  def lineno
    @event[:lineno]
  end

  #
  # @return [Module]
  #   Returns the class or module where an event occurred.
  #
  def from_module
    @event[:from_module]
  end

  #
  # @return [Symbol]
  #   Returns name of a method where an event occurred.
  #
  def from_method
    @event[:from_method]
  end

  #
  # @return [Binding]
  #   Returns a Binding object in context of where an event occurred.
  #
  def binding
    @event[:binding]
  end

  #
  # @return [Boolean]
  #   Returns true when an event is a method call by a method implemented in C.
  #
  def c_call?
    @type == "c-call"
  end

  #
  # @return [Boolean]
  #   Returns true when an event is a method call by a method implemented in Ruby.
  #
  def rb_call?
    @type == "call"
  end

  #
  # @return [Boolean]
  #   Returns true when an event is a method return from a method implemented in C.
  #
  def c_return?
    @type == "c-return"
  end

  #
  # @return [Boolean]
  #   Returns true when an event is a method return from a method implemented in Ruby.
  #
  def rb_return?
    @type == "return"
  end

  #
  # @return [String]
  #
  def inspect
    "#<Trip::Event:0x#{__id__.to_s(16)} " \
    "type='#{type}'" \
    "file='#{file}' lineno='#{lineno}' " \
    "from_module='#{from_module}' from_method='#{from_method}' " \
    "binding=#{binding.inspect}>"
  end

  #
  # @return [Binding]
  #   Returns a binding object in the context of an instance of {Trip::Event}.
  #
  def __binding__
    ::Kernel.binding
  end
end
