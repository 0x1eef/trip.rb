# frozen_string_literal: true

class Trip::Event < BasicObject
  # @attr_reader [Module] module
  #  The module where an event occurred.
  #
  # @attr_reader [Symbol] method_name
  #  The name of a method where an event occurred.
  CallerContext = ::Struct.new(:module, :method_name)

  # @return [String]
  #  Returns the name of event as reported by the "Thread#set_trace_func" API.
  #  Examples: "c-call", "call", "c-return", "return", ...
  attr_reader :name

  def initialize(name, event)
    @name = name
    @event = event
  end

  # @return [String]
  #  Returns the path where an event occurred.
  def path
    @event[:path]
  end

  # @return [Integer]
  #  Returns the line number where an event occurred,
  def lineno
    @event[:lineno]
  end

  # @return [Trip::Event::CallerContext]
  #  Returns a struct containing the module and method name where
  #  an event occurred.
  def caller_context
    CallerContext.new @event[:module], @event[:method_name]
  end

  # @return [Binding]
  #  Returns a Binding object in the context of where an event occurred.
  def binding
    @event[:binding]
  end

  # @return [Boolean]
  #  Returns true when an event is for a C method call.
  def c_return?
    @name == "c-return"
  end

  # @return [Boolean]
  #  Returns true when an event is for a Ruby method return.
  def rb_return?
    @name == "return"
  end

  # @return [Boolean]
  #   Returns true when an event is for a C method call.
  def c_call?
    @name == "c-call"
  end

  # @return [Boolean]
  #   Returns true when an event is for a Ruby method call.
  def rb_call?
    @name == "call"
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

  # @example
  #  event1.signature  # => "Foo.bar"
  #  event2.signature  # => "Foo#bar"
  #
  # @return [String]
  #  Returns the signature for the method where an event occurred
  #  by using "#" to denote instance methods and using "." to denote
  #  singleton methods.
  def signature
    [
      caller_context.module.to_s,
      method_notation,
      caller_context.method_name
    ].join
  end

  # @return [String]
  def inspect
    "#<Trip::Event:0x#{__id__.to_s(16)} " \
    "name='#{name}'" \
    "file='#{path}' lineno='#{lineno}' " \
    "module='#{caller_context.module}' method_name='#{caller_context.method_name}' " \
    "binding=#{binding.inspect}>"
  end

  # @return [Binding]
  #  Returns a binding object for an instance of {Trip::Event}.
  def __binding__
    ::Kernel.binding
  end

  private

  def method_notation
    if binding
      # If self is a class or module return '.'
      # If self is an instance of a class return '#'.
      ::Module === binding.eval('self') ? '.' : '#'
    else
      singleton_method_names = caller_context.module.singleton_methods
      singleton_method_names.include?(caller_context.method_name) ? '.' : '#'
    end
  end
end
