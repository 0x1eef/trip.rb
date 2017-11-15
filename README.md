Mirrors:

* [GitHub](https://github.com/0x1eef/trip)
* [GitLab](https://gitlab.com/0x1eef/trip)

__Trip__

Provides a concurrent tracer capable of suspending and resuming code as it
is being traced. It yields control between two threads, usually the main
thread and a thread that Trip creates.

Not suitable outside development environments because it is built on
`Thread#set_trace_func`, which can be notoriously slow.

__Examples__

__1.__

The code being traced is paused on method call and method return events
by default. The method calls or returns could originate from within methods
implemented in C, and Ruby. It is possible to pause Trip when a method is
implemented in either C or Ruby but the default is to catch both.

```ruby
def add(x,y)
end

trip = Trip.new { add(20,50) }
event1 = trip.start  # returns a Trip::Event (for the method call of "#add")
event2 = trip.resume # returns a Trip::Event (for the method return of "#add")
event3 = trip.resume # returns nil (thread exits)
```

__2.__

A Proc that returns true or false can be used to pause the tracer.
It receives an instance of "Trip::Event" that can support the Proc
when it is making a decision on whether or not it should pause the
tracer by returning true, or to continue by returning false.

```ruby
class Planet
  def initialize(name)
    @name = name
  end

  def echo
    'ping'
  end
end

trip = Trip.new { Planet.new('earth').echo }
trip.pause_when { |event| event.rb_call? }
event1 = trip.start   # returns a Trip::Event (for the method call of Planet#initialize)
event2 = trip.resume  # returns a Trip::Event (for the method call of Planet#echo)
event3 = trip.resume  # returns nil (thread exits)
```

__3.__

"Trip::Event#binding" provides the option to eval code in the scope of where
an event has happened. Changes to state like local variables can alter the
outcome of code at runtime and while a trace is still in progress. Being able
to do something like the example below is why I started to work on Trip.

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

It is possible for "Trip#start" or "Trip#resume" to raise due to an internal error,
or if the pause Proc raises an exception. "Trip::PauseError" is raised when
the pause Proc raises an exception, and Trip::InternalError is raised
for every other case. Both have Trip::Error as a superclass. The original cause of
an exception is stored in "Trip::Error#cause" and it can be useful to see why
Trip::PauseError or Trip::InternalError was raised.

```ruby
begin
  trip = Trip.new { puts 'Hello' }
  trip.pause_when { |event| raise RuntimeError, 'hello from readme.md' }
  trip.start # this method will raise
rescue Trip::PauseError => e
  p e.cause.message # => 'hello from readme.md'
end
```

__Install__

**NOTE:**

* Runs on Ruby 2.1 or later.
* Probably doesn't work well on anything other than CRuby.

Bundler:

    gem "trip", git: "https://gitlab.com/0x1eef/trip.git"

Build gem from source:

    git clone https://gitlab.com/0x1eef/trip
    cd trip
    gem build trip.gemspec
    gem install trip*.gem

__License__

[MIT](./LICENSE.txt).
