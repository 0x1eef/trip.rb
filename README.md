# <a id='top'>trip.rb</a>

Trip.rb is a concurrent tracer that can pause (suspend) and resume the code
it is tracing. The tracer yields control between two threads, typically
the main thread and a thread that Trip.rb creates. The process of yielding
control back and forth between the two threads is repeated until the trace
has finished.

Trip.rb is implemented using [TracePoint](https://docs.w3cub.com/ruby~3/tracepoint) -
where as before Trip.rb used ["Thread#set_trace_func"](https://docs.w3cub.com/ruby~3/thread#method-i-set_trace_func). It was decided to update Trip.rb's internals
to use TracePoint instead - starting from Trip v3.0.0.

## Examples

**1. Concurrent**

One might wonder: what is meant by "concurrent tracer" ? In the context of Trip,
it can be explained as a tracer that spawns a new thread to run (and trace) a
block of Ruby code. The tracer then pauses the new thread when a condition is met,
and then yields control back to the calling thread (normally the main thread).

The main thread can then resume the tracer, and repeat this process until the
tracer thread exits. While the tracer thread is paused, the main thread can examine
event information, and eval code in the context (Binding) of where an event occurred.

This example illustrates the explanation in code:

```ruby
require "trip"

module Greeter
  def self.say(message)
    puts message
  end
end

##
# Create a new Trip.
# Pause for events coming from "Greeter.say".
trip = Trip.new { Greeter.say "Hello" }
trip.pause_when { |event| event.self == Greeter && event.method_id == :say }

##
# Start the tracer by calling "Trip#start".
# Afterwards, pause the tracer on the call of
# "Greeter.say". The argument of "Greeter.say",
# `message` is then changed.
event1 = trip.start
print event1.name, " ", event1.method_id, "\n"
print "self: ", event1.self, "\n"
event1.binding.eval("message << ' rubyist!'")

##
# Resume the tracer thread from its paused state,
# and then pauses again for the method return of
# "Greeter.say".
event2 = trip.resume
print event2.name, " ", event2.method_id, "\n"

##
# This call to "trip.resume" returns nil, and
# exits the tracer thread.
event3 = trip.resume
print event3.inspect, "\n"

# == Produces the output:
# call say
# self: Greeter
# Hello rubyist!
# return say
# nil

```

**2. Filter events**

The tracer will listen for method call and return events from methods
implemented in either C or Ruby by default. The `events:` keyword
argument can be used to narrow or extend the scope of what events the
tracer will listen for.

The `events:` keyword argument uses a TracePoint feature
that allows certain events to be included or excluded from
the trace. For excluded events, no events are generated by
TracePoint or Trip. If the goal is to listen for all events
`Trip.new(events: :all) { ... }` can be used. A full list of
event names can be found in the [Trip::Event docs](https://0x1eef.github.io/x/trip.rb/Trip/Event.html).

In the example, the `events:` keyword argument specifies call and
return events from methods implemented in Ruby, and that reduces the
noise from call and return events from methods implemented in C. Another
thing to keep in mind, `trip.resume` is used to both start and resume
the tracer in the example - without ever calling `trip.start`.

```ruby
require "trip"

def add(x, y)
  Kernel.puts x + y
end

##
# Create an instance Trip, and set
# the events to listen for with the "events:"
# keyword argument.
trip = Trip.new(events: %i[call return]) { add(20, 50) }
while event = trip.resume
  print event.name, " ", event.method_id, "\n"
end

# == Produces the output:
# call add
# 70
# return add
```

**3. `Trip#pause_when`**

In the previous example we saw how to filter events.
The events specified by the `events:` keyword argument
decide what events will be made available to `Trip#pause_when`.
By default `Trip#pause_when` will pause the tracer on method call
and return events from methods implemented in either C or Ruby.

In the example, the logic for pausing the tracer is changed to pause
when a new module / class is defined with the `module Name` or `class Name`
syntax. Keep in mind - as this code runs, the tracer is paused and resumed
multiple times, and so are the class definitions.

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

trip.pause_when(&:module_opened?)
while event = trip.resume
  print event.self, " class opened", "\n"
end

# == Produces output:
# Foo class opened
# Bar class opened
# Baz class opened
```

**4. Rescued by a REPL**

It is possible for Trip to listen for the `raise` event, and
then pause the tracer when it is encountered. After that, one can
start an IRB session in the context of where an exception has
been raised.

The example illustrates that in code:

```ruby
require "trip"

module Greeter
  def self.say(message)
    putzzz message
  end
end

trip = Trip.new(events: %i[raise]) { Greeter.say("hello") }
trip.pause_when(&:raise?)
event = trip.start
event.binding.irb
```

## Resources

* [docs: 0x1eef.github.io/x/trip.rb](https://0x1eef.github.io/x/trip.rb)
* [source code: github.com/0x1eef/trip.rb](https://github.com/0x1eef/trip.rb)

## Install

Trip.rb is available as a RubyGem:

    gem install trip.rb

## <a id='license'>License</a>

This project uses the MIT license - see [LICENSE.txt](./LICENSE.txt) for details.
