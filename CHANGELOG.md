__v0.2.0__

* By default pause the tracer when it encounters Ruby method call and
  return events (ie those not implemented in C). The call and return events from
  methods implemented in C are ignored by default, although they can still be
  identified and used from a block given to `Trip#pause_when`:

  ```ruby
  trip = Trip.new { Kernel.puts 123 }
  trip.pause_when {|event| event.c_call? || event.c_return? }
  event1 = trip.start 
  ```

__v0.1.2__

  * Add magic frozen string comment to all `lib/` files (Riny 2.3+).

  * Remove `Trip#in_progress?``.

  * Rename `Trip::Event#name` as `Trip::Event#type`.

  * Rename `Trip::Event#method_name` as `Trip::Event#from_method`.

  * Rename `Trip::Event#module_name` as `Trip::Event#from_module`.

  * Raise `Trip::PauseError` when `Trip#pause_when` predicate causes the
    tracer to crash.
