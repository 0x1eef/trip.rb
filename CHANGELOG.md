__v0.1.2__

  * Publish on Rubygems.org as trip.rb
  * Add magic frozen string comment to all lib/ files, for 2.3+
  * Remove "Trip#in_progress?".
  * Rename "Trip::Event#name" as "Trip::Event#type".
  * Rename "Trip::Event#method_name" as "Trip::Event#from_method"
  * Rename "Trip::Event#module_name" as "Trip::Event#from_module"
  * Raise Trip::PauseError when the pause_when predicate causes the tracer to crash
