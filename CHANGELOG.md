__HEAD__

  * Remove "Trip#in_progress?".
  * Rename "Trip::Event#name" as "Trip::Event#type".
  * Rename "Trip::Event#method_name" as "Trip::Event#from_method"
  * Rename "Trip::Event#module_name" as "Trip::Event#from_module"
  * Raise Trip::PauseError when the pause_when predicate causes the tracer to crash
