# trip.rb

* [Introduction](#introduction)
* [Examples](#examples)
* [Install](#install)
* [License](#license)

## <a id='introduction'>Introduction</a>

Trip is a concurrent tracer that can pause, resume and alter code while it is
being traced. Trip yields control between two threads, typically the main thread
and a thread that Trip creates.

Under the hood, Trip uses `Thread#set_trace_func` and spawns a new thread
dedicated to running and tracing a block of Ruby code. Control is yielded
between the main thread and this new thread until the trace completes.

## <a id='examples'>Examples</a>

__1.__

By default the code being traced is paused on method call and return events
from methods implemented in Ruby. Method call and return events could originate
from methods implemented in either C or Ruby. Changing the default behavior and
pausing the tracer on events from methods implemented in C is covered in
example **2**.

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

__2.__

A block that returns true or false can be used to pause the tracer and
change the default behavior. It receives an instance of `Trip::Event` to
utilize. For example to pause on method call and return events from methods
implemented in C:

```ruby
trip = Trip.new { Kernel.puts 1+6 }
trip.pause_when { |event| event.c_call? || event.c_return? }
event1 = trip.start # returns a Trip::Event (for a method call to a method implemented in C)
trip.stop           # returns nil, thread exits
```

__3.__

`Trip::Event#binding` returns a `Binding` object that provides access to the context
of where an event occurred, it can be used to execute code in that same context
through `Binding#eval` and this allows the surrounding environment to be changed
while the tracer thread is suspended but the trace is still in progress:

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

__4.__

It's possible for `Trip#start` or `Trip#resume` to raise an error, either due
to an internal Trip error (`Trip::InternalError`) or due to an error in the
block given to `Trip#pause_when` (`Trip::PauseError`). In both cases,
`Exception#cause` will return the exception that caused the error:

```ruby
begin
  trip = Trip.new { puts 'Hello' }
  trip.pause_when { |event| raise RuntimeError, 'hello from readme.md' }
  trip.start # This method will raise
rescue Trip::InternalError => e
  # Won't be reached
rescue Trip::PauseError => e
  p e.cause.message # => 'hello from readme.md'
end
```

## <a id='install'>Install</a>

    gem install trip.rb

## <a id='license'>License</a>

This project uses the MIT license, see [LICENSE](./LICENSE.txt) for details.
