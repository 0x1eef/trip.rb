# frozen_string_literal: true

require_relative "setup"
require "trip"

trip = Trip.new(%i[c_call]) { require "pry" }
trip.pause_when { _1.method_id == :require }
events = trip.to_a

##
# The number of calls to require
p events.size

##
# The paths that were required
p events.map { _1.binding.eval("path") }
