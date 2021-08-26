# frozen_string_literal: true

class Trip::Event < BasicObject
  # @return [String]
  #  Returns the type of event as reported by the "Thread#set_trace_func" API.
  #  Examples: "c-call", "call", "c-return", "return", ...
  attr_reader :type

  def initialize(type, event)
    @type = type
    @event = event
  end

  # @return [String]
  #  Returns the path where an event occurred.
  def file
    @event[:file]
  end

  # @return [Integer]
  #  Returns the line number where an event occurred,
  def lineno
    @event[:lineno]
  end

  # @return [Module]
  #  Returns the class or module where an event occurred.
  def from_module
    @event[:from_module]
  end

  # @return [Symbol]
  #  Returns the method name where an event occurred.
  def from_method
    @event[:from_method]
  end

  # @return [Binding]
  #  Returns a Binding object in the context of where an event occurred.
  def binding
    @event[:binding]
  end

  # @return [Boolean]
  #  Returns true when an event is for a C method call.
  def c_return?
    @type == "c-return"
  end

  # @return [Boolean]
  #  Returns true when an event is for a Ruby method return.
  def rb_return?
    @type == "return"
  end

  # @return [Boolean]
  #   Returns true when an event is for a C method call.
  def c_call?
    @type == "c-call"
  end

  # @return [Boolean]
  #   Returns true when an event is for a Ruby method call.
  def rb_call?
    @type == "call"
  end

  # @return [Boolean]
  #  Returns true if the event is for a Ruby or C method call.
  def call?
    c_call? || rb_call?
  end

  # @return [Boolean]
  #  Returns true if the event is for a Ruby or C method return.
  def return?
    c_return? || rb_return?
  end

  # @return [String]
  def inspect
    "#<Trip::Event:0x#{__id__.to_s(16)} " \
    "type='#{type}'" \
    "file='#{file}' lineno='#{lineno}' " \
    "from_module='#{from_module}' from_method='#{from_method}' " \
    "binding=#{binding.inspect}>"
  end

  # @return [Binding]
  #  Returns a binding object for an instance of {Trip::Event}.
  def __binding__
    ::Kernel.binding
  end
end
