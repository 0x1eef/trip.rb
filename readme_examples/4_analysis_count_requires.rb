# frozen_string_literal: true

require_relative "setup"
require "trip"

trip = Trip.new(%i[c_call]) { require "pry" }
trip.pause_when { _1.method_id == :require }
p trip.to_a.size

##
# 169
