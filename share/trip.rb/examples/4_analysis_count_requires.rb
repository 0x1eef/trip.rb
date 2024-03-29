#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "setup"
require "trip"
$stdout.sync = true

trip = Trip.new(%i[call]) { require "pry" }
trip.pause_when { _1.method_id == :require }
events = trip.to_a

##
# The number of calls to require
puts events.size

##
# The paths that were required
puts events.map { _1.binding.eval("path") }
