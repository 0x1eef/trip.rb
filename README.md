# trip.rb

**Table of contents**

* [Introduction](#introduction)
* [Examples](#examples)
* [Install](#install)
* [License](#license)

## <a id='introduction'>Introduction</a>

Trip is a concurrent tracer that can pause, resume and alter code while it is
being traced. Trip yields control between two threads, typically the main thread
and a thread that Trip creates.

Under the hood, Trip uses `Thread#set_trace_func` and spawns a new thread
dedicated to running a block of Ruby code. Control is then yielded between 
the calling thread and Trip's thread until the trace completes.

## <a id='examples'>Examples</a>

**#1**

By default the tracer pauses upon method call and return events from Ruby methods:

```ruby
def add(x,y)
  # C method calls ignored by the tracer:
  Kernel.puts x + y
end

trip = Trip.new { add(20,50) }
event1 = trip.start  # returns a Trip::Event (for the method call of "#add")
event2 = trip.resume # returns a Trip::Event (for the method return of "#add")
event3 = trip.resume # returns nil (thread exits)
```

**#2**

The predicate that decides when the tracer will pause can be customized to meet 
your own criteria through `#pause_when`:

```ruby
trip = Trip.new { Kernel.puts 1+6 }
trip.pause_when { |event| event.c_call? || event.c_return? }
event1 = trip.start # returns a Trip::Event (for a method call to a method implemented in C)
trip.stop           # returns nil, thread exits
```

**#3**

`Trip::Event#binding` returns a `Binding` object that provides access to the context
of where an event occurred. It can be used to run code in that same context through 
`Binding#eval`. This allows the surrounding environment to be changed while the tracer 
is paused:

```ruby
def add(x,y)
  to_s = "#{x} + #{y}"
end

trip = Trip.new { add(2,3) }
event1 = trip.start           # returns a Trip::Event (for the method call of add)
event1.binding.eval('x = 4')  # returns 4 (also changes the value of 'x')
event2 = trip.resume          # returns a Trip::Event (for the method return of add)
event2.binding.eval('to_s')   # returns '4 + 3'
trip.stop                     # returns nil, thread exits
```

## <a id='install'>Install</a>

    gem install trip.rb

## <a id='license'>License</a>

This project uses the MIT license, see [LICENSE](./LICENSE.txt) for details.
