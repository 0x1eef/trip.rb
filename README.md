## About

Trip is a concurrent tracer that can pause and resume the code
it is tracing. Trip yields control between two Fibers - typically
the root Fiber and a Fiber that Trip creates. The process of yielding
control back and forth between the two Fibers can be repeated until the
code being traced has finished and exits normally. Trip is currently implemented
using [TracePoint](https://www.rubydoc.info/gems/tracepoint/TracePoint).

## Examples

### Concurrency

#### A concurrent tracer

Trip can be explained as a tracer that spawns a new Fiber to run, and trace
a block of Ruby code. Trip then pauses the new Fiber when a condition is met,
and yields control back to the root Fiber.

The root Fiber can then resume the tracer, and repeat this process until the
new Fiber exits. While the new Fiber is paused, the root Fiber can examine
event information and evaluate code in the
[Binding (context)](https://rubydoc.info/stdlib/core/Binding)
of where an event occurred. The following example hopes to paint a clearer picture
of what that means in practice:

```ruby
require "trip"

module Stdout
  def self.write(message)
    puts(message)
  end
end

##
# Create a new Trip.
# Pause for events coming from "Stdout.write".
trip = Trip.new { Stdout.write("Ruby is") }
trip.pause_when { |event| event.self == Stdout && event.method_id == :write }

##
# Enter "Stdout.write" - then mutate a local
# variable while the tracer is paused.
event = trip.start
event.binding.eval("message << ' cool.'")

##
# Execute the "puts(message)" line, and pause
# for the return of "Stdout.write".
event = trip.resume

##
# Exit the "Stdout.write" method, and the
# tracer.
event = trip.resume

##
# Ruby is cool.
```

### Filter

#### Events

Trip will listen for method call and return events from methods
implemented in either C or Ruby by default. The first argument given
to `Trip.new` can specify a list of event names to listen for other than
the defaults. All events can be included by using `Trip.new('*') { ... }`.
A full list of event names can be found in the
[Trip::Event docs](https://0x1eef.github.io/x/trip.rb/Trip/Event.html).
The following example listens for call and return events from Ruby methods,
and excludes methods implemented in C:

```ruby
require "trip"

def add(x, y)
  puts(x + y)
end

trip = Trip.new(%i[call return]) { add(20, 50) }
while event = trip.resume
  print event.name, " ", event.method_id, "\n"
end

##
# call add
# 70
# return add
```

#### `Trip#pause_when`

In the previous example we saw how to specify what events to listen
for. **The events specified by the first argument given to `Trip.new`
decide what events will be made available to `Trip#pause_when`.**
By default, the `Trip#pause_when` method will cause the tracer to pause
for each event it is configured to listen for, but custom logic can be
provided to decide whether the tracer should pause or not. For example,
you might want to pause the tracer only when an event originates from
a certain file, class, or method.

The following example demonstrates how to pause the tracer for every
method call / return that originates from the filename `http.rb`:

```ruby
require "trip"
require "net/http"

trip = Trip.new do
  uri = URI.parse("https://www.ruby-lang.org")
  Net::HTTP.get_response(uri)
end
trip.pause_when { |event| File.basename(event.path) == "http.rb" }

print "Event".ljust(10), "Location".ljust(15), "Method", "\n"
while event = trip.resume
  sigil = event.method_type == "singleton_method" ? "." : "#"
  print "#{event.name}".ljust(10),
        "#{File.basename(event.path)}:#{event.lineno}".ljust(15),
        event.module_name, sigil, event.method_id,
        "\n"
end

##
# Event     Location       Method
# call      http.rb:470    Net::HTTP.get_response
# c_call    http.rb:480    URI::HTTPS#port
# c_return  http.rb:480    URI::HTTPS#port
# c_call    http.rb:481    URI::HTTPS#scheme
# c_return  http.rb:481    URI::HTTPS#scheme
# c_call    http.rb:481    String#==
# c_return  http.rb:481    String#==
# call      http.rb:668    Net::HTTP.start
# ...
```

### Analysis

#### Require count

The `Trip#to_a` method can perform a trace from start to finish,
and then return an array of `Trip::Event` objects. The following
example returns the number of files that Pry v0.14.1 requires,
including duplicate calls to require, and without any plugins
being used.

When we exclude `require "pry"` from the count, the number is 165
rather than 166:

```ruby
require "trip"

trip = Trip.new(%i[call]) { require "pry" }
trip.pause_when { _1.method_id == :require }
events = trip.to_a

##
# The number of calls to require
puts events.size

##
# The paths that were required
puts events.map { _1.binding.eval('path') }

##
# 166
# pry
# pry/version
# pry/last_exception
# pry/forwardable
# forwardable
# forwardable/impl
# pry/helpers/base_helpers
# pry/helpers/documentation_helpers
# pry/helpers
# pry/helpers/base_helpers
# pry/helpers/options_helpers
# ...
```

### Rescue

#### IRB

Trip can listen for the `raise` event, and then pause the tracer when
it is encountered. Afterwards, an IRB session can be started in the
[Binding (context)](https://rubydoc.info/stdlib/core/Binding)
of where an exception was raised. The following example demonstrates
how that works in practice:

```ruby
require "trip"

module Stdout
  def self.write(message)
    putzzz(message)
  end
end

trip = Trip.new(%i[raise]) { Stdout.write("hello") }
trip.pause_when(&:raise?)
event = trip.start
event.binding.irb
```

## Sources

* [Source code (GitHub)](https://github.com/0x1eef/trip.rb#readme)
* [Source code (GitLab)](https://gitlab.com/0x1eef/trip.rb#about)

## Install

trip.rb is distributed as a RubyGem through its git repositories. <br>
[GitHub](https://github.com/0x1eef/trip.rb),
and
[GitLab](https://gitlab.com/0x1eef/trip.rb)
are available as sources.

## <a id='license'>License</a>

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/).
<br>
See [LICENSE](./LICENSE).
