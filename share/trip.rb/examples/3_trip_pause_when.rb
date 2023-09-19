#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "setup"
require "trip"
require "net/http"
$stdout.sync = true

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
