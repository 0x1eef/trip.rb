# <a id='top'>trip.rb</a>

**Table of contents**

* [Introduction](#introduction)
* [Getting started](#examples) 
  * [Using trip.rb as a concurrent tracer](#as-a-concurrent-tracer)
      * [Install](#install-trip-1)
      * [Usage](#concurrent-tracer-usage)
          * [Perform a trace with default settings](#usage-1)
          * [Perform a trace with custom settings](#usage-2)
          * [Access and alter the execution context of a Trip::Event](#usage-3)
  * [Using trip.rb as a stacktrace analyzer](#as-a-stacktrace-analyzer)
      * [Install](#install-trip-2)
      * [Usage](#stacktrace-analyzer-usage)
          * [Analyze a method call](#stacktrace-analyzer-method)
          * [Set precision used for execution time](#stacktrace-analyzer-precision)
          * [Write stacktrace analysis to a custom IO](#stacktrace-custom-io)
      * [Best guessing C methods](#c-note)
* [License](#license)

## <a id='introduction'>Introduction</a>

Trip.rb is a concurrent tracer that can pause, resume and alter the code 
it is tracing. The tracer yields control between two threads, typically 
the main thread and a thread that Trip.rb creates. Bundled with Trip.rb 
is a [stacktrace analyzer](#as-a-stacktrace-analyzer) that serves as an 
example and as a useful debugging tool. 

Under the hood, Trip uses `Thread#set_trace_func` and spawns a new thread
dedicated to running a block of Ruby code. Control is then yielded between 
the calling thread and Trip's thread until the trace completes.

## <a id='examples'>Getting started</a>

### <a id='as-a-concurrent-tracer'>Using trip.rb a concurrent tracer</a>

<a id=install-trip-1>**Install**</a>

Trip.rb is available as a rubygem:

    gem install trip.rb

<a id='concurrent-tracer-usage'>**Usage**</a>


**<a id='usage-1'>1. Perform a trace with default settings</a>**

By default the tracer pauses on method call and method return events from 
methods implemented in Ruby. This can be changed to cover both methods 
implemented in C and Ruby - or meet other criteria - using `Trip#pause_when`, 
which will be covered in the next example. 

For this example a trace is done with the default settings.

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

**2. <a id='usage-2'>Perform a trace with custom settings</a>**

The logic for deciding when to pause the tracer can be customized using the 
`Trip#pause_when` method. The `#pause_when` method accepts a block or object
implementing `#call`. The block or object is then called by Trip.rb during a 
trace to decide if the trace should pause or continue uninterrupted.

The block or an object's `#call` method is called with an instance of `Trip::Event` 
to help support it in making its decision to pause or continue. A truthy return 
value pauses the tracer and a falsey return value allows the trace to continue.

This example configures Trip.rb to pause on method call and return events from 
methods implemented in C (as opposed to those implemented in Ruby). Note that 
when to pause can be based on other criteria from an event as well - not just
method call and return events.

```ruby
trip = Trip.new { Kernel.puts 1+6 }
trip.pause_when { |event| event.c_call? || event.c_return? }
event1 = trip.start  # Event for c-call (Kernel#puts)
event2 = trip.resume # Event for c-call (IO#puts)
```

**3. <a id='usage-3'>Access and alter the execution context of a Trip::Event</a>**

`Trip::Event#binding` returns a [`Binding`](https://rubydoc.info/stdlib/core/Binding) object 
that captures the execution context of where an event occurred. `Binding#eval` can be used
to evaluate code in the captured execution context and that allows for altering the execution
context while the code being traced is paused. 

This feature works best for methods implemented in Ruby. For methods implemented in C, the 
Binding provided will be for the nearest Ruby method - which can be confusing if you're not
aware of it.


```ruby
def add(x,y)
  to_s = "#{x} + #{y}"
end

trip = Trip.new { add(2,3) }
event1 = trip.start           # Returns "call" Trip::Event 
event1.binding.eval('x = 4')  # Change "x" to 4.
event2 = trip.resume          # Returns "return" Trip::Event
event2.binding.eval('to_s')   # returns '4 + 3'
trip.resume                   # returns nil, thread exits
```

[Back to top](#top)

### <a id='as-a-stacktrace-analyzer'>Using trip.rb as a stacktrace analyzer</a>

Trip.rb implements a stacktrace analyzer that can be useful for debugging and 
gaining insight into the code being traced. One day I might extract it into 
its own gem - for now it is shipped with the Trip.rb gem.

<a id=install-trip-2>**Install**</a>

First install the trip.rb and paint gems.  
The paint gem is used for colorized output by the analyzer. 

```
gem install trip.rb paint
```

<a id='stacktrace-analyzer-usage'>**Usage**</a>

**<a id='stacktrace-analyzer-method'> 1. Analyze a method call</a>**

The analyzer can be required as `trip/analyzer`.  
The analyzer can be invoked by calling `Trip.analyze { <code> }`. In
this example setting the `page` keyword argument to true opens the stacktrace 
analysis using the pager `less`.

```ruby
require "trip/analyzer"
require "xchan"
Trip.analyze(page: true) { xchan.send 123 }
```

When the above code is run an analysis of the stacktrace similar to this should appear:

![preview 1](https://github.com/0x1eef/trip.rb/raw/master/screenshots/screenshot_1.png)

[Back to top](#top)

<a id='stacktrace-analyzer-precision'>**2. Set precision used for execution time**</a>

The default precision used when printing the execution time of a method is 4. 
It can be changed with the `precision` keyword argument. For example:

```ruby
Trip.analyze(page: true, precision: 2) { sleep 2.553 }
```

shows a stacktrace analysis similar to this:

![preview 2](https://github.com/0x1eef/trip.rb/raw/master/screenshots/screenshot_2.png)

[Back to top](#top)

<a id='stacktrace-custom-io'>**3. Write stacktrace analysis to a custom IO**</a>

The stacktrace analysis can be written to a custom IO - such as a StringIO - by setting
the `io` keyword argument. Disabling color can be useful for a case like this 
as well, which can be done by setting the `color` keyword argument to false.

For example:

```ruby
str_io = StringIO.new
Trip.analyze(io: str_io, color: false) { sleep 2.55 }
puts str_io.string
```

[Back to top](#top)

### <a id='c-note'>Best guessing C methods</a> 

Trip.rb uses `#` to denote an instance method and it uses `.` to denote a 
singleton method (also known as a class method) in the traces it generates.

This proved diffilcult to determine for methods implemented in C because 
their binding's self is the self of the nearest Ruby method rather than the 
self of the method being traced - as is the case with methods implemented 
in Ruby.

The best solution I found to date was to take a best guess on which notation 
should be used for methods implemented in C. The best guess is sometimes
incorrect. It's worth keeping that in mind for `c-call` and `c-return` events.

Thankfully, methods implemented in Ruby don't have this problem.

[Back to top](#top)

## <a id='license'>License</a>

This project uses the MIT license - see [LICENSE.txt](./LICENSE.txt) for details.
