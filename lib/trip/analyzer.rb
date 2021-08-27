require "trip"
require "stringio"
require "paint"

class Trip::Analyzer
  require_relative "analyzer/printer"
  include Trip::Analyzer::Printer

  # @return [Integer]
  #  Returns the default precision used when printing a method's
  #  execution time.
  DEFAULT_PRECISION = 4

  # @example
  #  analyzer = Trip::Analyzer.new { Digest::MD5.hexdigest("hello world") }
  #  analyzer.analyze
  #
  # @return [Trip::Analyzer]
  def initialize
    @trip = Trip.new { yield }
    @trip.pause_when { |event| event.call? || event.return? }
    @method_call_count = 0
    @c_call_count = 0
    @rb_call_count = 0
  end

  # @param [Integer] precision
  #  An integer representing the precision to be used when printing a method's
  #  execution time.
  #
  # @return [void]
  def analyze(precision: DEFAULT_PRECISION)
    stringio = StringIO.new
    open_count = 0
    indent_by = 0
    events, duration = run_code
    print_about
    events.reverse_each do |event, duration|
      indent_by = open_count * 2
      open_count, indent_by = adjust_counters(event, open_count, indent_by)
      print_event(stringio, event, indent_by, duration, precision)
    end
    print_summary(duration, precision)
    print_trace(stringio, precision)
  end

  private

  def run_code
    start = Process.clock_gettime(Process::CLOCK_REALTIME)
    events = []
    while (event = @trip.resume)
      if event.return?
        call_event, = events.find { |(e, _)| event.caller_context == e.caller_context && e.call? }
        events.unshift([event, event.created_at - call_event.created_at])
      else
        events.unshift([event, nil])
      end
    end
    finish = Process.clock_gettime(Process::CLOCK_REALTIME)
    [events, finish - start]
  end

  def adjust_counters(event, open_count, indent_by)
    if event.return?
      open_count -= 1
    elsif event.call?
      @method_call_count += 1
      event.c_call? ? @c_call_count += 1 : @rb_call_count += 1
      open_count += 1
      indent_by = open_count * 2
    end
    [open_count, indent_by]
  end

  def event_path(event)
    path = [
      File.basename(File.dirname(event.path)),
      File.basename(event.path)
    ].join(File::Separator)
    "#{path}:#{event.lineno}"
  end
end

# Analyzes a block of Ruby code by printing a
# detailed trace to $stdout.
#
# @example
#  Trip.analyze { ERB.new("").result }
#
# @param (see Trip::Analyzer#analyze)
#
# @return [void]
def Trip.analyze precision: Trip::Analyzer::DEFAULT_PRECISION, &blk
  Trip::Analyzer.new(&blk).analyze(precision: precision)
end
