require 'trip'
require 'stringio'
require 'paint'

class Trip::Analyzer
  require_relative 'analyzer/printer'
  include Trip::Analyzer::Printer

  # @example
  #  analyzer = Trip::Analyzer.new { Digest::MD5.hexdigest("hello world") }
  #  analyzer.analyze
  #
  # @return [Trip::Analyzer]
  def initialize(&blk)
    @trip = Trip.new { yield }
    @trip.pause_when { |event| event.call? || event.return? }
    @method_call_count = 0
    @c_call_count = 0
    @rb_call_count = 0
  end

  def analyze
    stringio   = StringIO.new
    open_count = 0
    indent_by  = 0
    events, duration = run_code
    print_about
    events.each do |event, duration|
      indent_by = open_count * 2
      open_count, indent_by = adjust_counters(event, open_count, indent_by)
      print_event(stringio, event, indent_by, duration)
    end
    print_summary(duration)
    print_trace(stringio)
  end

  private

  def run_code
    start = Process.clock_gettime(Process::CLOCK_REALTIME)
    events = []
    while event = @trip.resume
      if event.return?
        call_event, = events.find { |(e, _)| event.caller_context == e.caller_context && e.call? }
        events.push([event, event.created_at - call_event.created_at])
      else
        events.push([event, nil])
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
    path = "#{path}:#{event.lineno}"
  end
end

def Trip.analyze &blk
  Trip::Analyzer.new(&blk).analyze
end