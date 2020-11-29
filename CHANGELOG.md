# CHANGELOG

## HEAD

* Nothing yet.

## v1.1.2

* gemspec: update email address.

## v1.1.1

* `Trip#pause_when` now returns `nil`.

* Fix YARD docs.

## v1.1.0

* Fix typo in constant name (`Trip::ProgessError` is now `Trip::ProgressError`).

* Remove the methods `Trip::Event.{method_calls, method_returns}` and the
  constants they used.

* Improve / update API documentation for the `Trip` class.

* Add API documentation for *all* `Trip::Event` methods.

* By default pause the tracer when it encounters Ruby method call and
  return events (ie those not implemented in C). The call and return events from
  methods implemented in C are ignored by default, although they can still be
  identified and used from a block given to `Trip#pause_when`:

  ```ruby
  trip = Trip.new { Kernel.puts 123 }
  trip.pause_when {|event| event.c_call? || event.c_return? }
  event = trip.start
  ```

## v0.1.2

  * Add magic frozen string comment to all `lib/` files (Riny 2.3+).

  * Remove `Trip#in_progress?``.

  * Rename `Trip::Event#name` as `Trip::Event#type`.

  * Rename `Trip::Event#method_name` as `Trip::Event#from_method`.

  * Rename `Trip::Event#module_name` as `Trip::Event#from_module`.

  * Raise `Trip::PauseError` when `Trip#pause_when` predicate causes the
    tracer to crash.
