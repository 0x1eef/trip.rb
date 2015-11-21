class Trip::Event < BasicObject
  Kernel = ::Kernel
  Time = ::Time
  METHOD_CALLS = %w(call c-call).freeze
  METHOD_RETURNS = %w(return c-return).freeze

  def self.method_calls
    METHOD_CALLS
  end

  def self.method_returns
    METHOD_RETURNS
  end

  attr_reader :type

  def initialize(type, event)
    @type = type
    @event = event
  end

  [:file, :lineno, :from_module, :from_method, :binding].each do |name|
    define_method(name) { @event[name] }
  end

  def inspect
    "#<Trip::Event:0x#{__id__.to_s(16)} " \
    "type='#{type}'" \
    "file='#{file}' lineno='#{lineno}' " \
    "from_module='#{from_module}' from_method='#{from_method}' " \
    "binding=#{binding.inspect}>"
  end

  #
  # @return [Binding]
  #   Returns a binding for an instance of {Trip::Event}.
  #
  def __binding__
    Kernel.binding
  end
end
