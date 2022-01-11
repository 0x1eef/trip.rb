# <a id='top'>trip.rb</a>

Trip.rb is a concurrent tracer that can pause (suspend) and resume the code
it is tracing. The tracer yields control between two threads, typically
the main thread and a thread that Trip.rb creates. The process of yielding
control back and forth between the two threads is repeated until the trace
has finished.

Trip.rb is implemented using [TracePoint](https://docs.w3cub.com/ruby~3/tracepoint) -
where as before Trip.rb used ["Thread#set_trace_func"](https://docs.w3cub.com/ruby~3/thread#method-i-set_trace_func).
TracePoint being its modern replacement, it was decided to update Trip.rb's
internals to use TracePoint instead - starting from v3.0.0.

## Demo

**Concurrent**

You might wonder what is meant by "concurrent tracer"; it can be explained
as a tracer that spawns a new thread to run and trace a block of Ruby code. The
tracer then pauses (suspends) the thread when a condition is encountered,
and yields control back to the calling thread (normally the main thread).

The main thread can then resume the tracer, and repeat this process until the
tracer thread exits. While the tracer thread is paused, the main thread can examine
event information, and evaluate code in the context (Binding) of where an
event occurred.

This example illustrates the explanation in code:

```ruby
require "trip"

##
# Create a new Trip.
# Pause for all events originating from "Kernel.puts".
trip = Trip.new { Kernel.puts 1+1 }
trip.pause_when { |event| event.module == Kernel && event.method_id == :puts }

##
# Start the tracer by spawning a new thread,
# which is then paused (suspended) upon the
# method call of "Kernel.puts"
event1 = trip.start
print event1.name, " ", event1.method_id, "\n"

##
# Resume the tracer thread from its paused state,
# and then pause again for the method return of
# "Kernel.puts".
event2 = trip.resume
print event2.name, " ", event2.method_id, "\n"

##
# This call to "trip.resume" returns nil, and
# exits the tracer thread.
event3 = trip.resume
print event3.inspect, "\n"

# == Produces the output:
# c_call puts
# 2
# c_return puts
# nil
```

**Decide what events to listen for**

The tracer will listen for method call and return events from methods
implemented in both C and Ruby by default. The "events" keyword
argument can be used to narrow or extend the scope of what events the
tracer will listen for.

This "events" option is built on a TracePoint feature
that allows certain events to be included or excluded from the trace, and
avoids geenerating events for excluded events. This also works in the other
direction, if you want to include all event types `Trip.new(events: :all) { ... }`
can be used. A full list of event names is available [here](https://docs.w3cub.com/ruby~3/tracepoint#class-TracePoint-label-Events).

In this example, we express interest in call and return events from
Ruby methods only, which reduces noise from C call and return
events in the code being traced. "trip.resume" is used to both
start and resume the tracer, without having to use "trip.start".

```ruby
require "trip"

def add(x, y)
  Kernel.puts x + y
end

##
# Create a new Trip.
# The events listened for are scoped to call
# and return events from Ruby methods (excludes C methods)
trip = Trip.new(events: %i[call return]) { add(20, 50) }
while event = trip.resume
  print event.name, " ", event.method_id, "\n"
end

# == Produces the output:
# call add
# 70
# return add
```

**Pause the tracer using custom logic**

In the previous example we saw how to specify what events to listen for,
in a similar vain the logic that decides when to pause the tracer can be
customized as well -- with the "Trip#pause_when" method. By default the
tracer will pause when it encounters call and return events from methods
implemented in either C or Ruby.

In this example, we change that logic to pause the tracer when a new
class or module is defined using "class Name" or "module Name". An important
point to not overlook is that as the tracer runs, the tracer is suspended
and resumed multiple times, and so are the class definitions.

```ruby
require "trip"

trip = Trip.new(events: %i[class]) do
  class Foo
  end

  class Bar
  end

  class Baz
  end
end

trip.pause_when { |event| event.module_def? }
while event = trip.resume
  print event.self, " class defined", "\n"
end

# == Produces output:
# Foo class defined
# Bar class defined
# Baz class defined
```

**Start an IRB session where an exception is raised**

In this example, we see how to start an IRB session exactly
where an exception was raised. The example listens for only
"raise" events, and when "putzzz" is called a NoMethodError 
is raised. This pauses the tracer, and allows the main thread
start an IRB session in the context of the "Person#greet" method.

```ruby
require "trip"

class Person
  def initialize(name: )
    @name = name
  end

  def greet
    putzzz "Hello"
  end
end

trip = Trip.new(events: %i[raise]) { Person.new(name: "0x1eef").greet }
trip.pause_when { |event| event.raise? }
event = trip.start
event.binding.irb
```

## Install

Trip.rb is available as a RubyGem:

    gem install trip.rb

## <a id='license'>License</a>

This project uses the MIT license - see [LICENSE.txt](./LICENSE.txt) for details.
