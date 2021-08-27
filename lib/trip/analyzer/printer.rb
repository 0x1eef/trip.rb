module Trip::Analyzer::Printer
  def print_about
    print Paint["About", :bold],
          "\n",
          "This analysis was brought to you by ", Paint["trip.rb", :bold], ".",
          "\n",
          "See https://github.com/0x1eef/trip.rb#readme for more information.",
          "\n"
  end

  def print_header_row
    print Paint["Path", :underline].ljust(38),
          Paint["Event", :underline].ljust(25),
          Paint["Method", :underline].rjust(5)
  end

  def print_trace(stringio)
    print "\n",
          Paint["Trace", :bold],
          "\n"
    print_header_row
    print "\n", stringio.string
  end

  def print_event(io, event, indent_by)
    io.print event_path(event).ljust(30),
            Paint[event.name, :green].ljust(24),
             " " * indent_by,
             Paint["-> ", :blue],
             event.signature,
             "\n"
  end

  def print_summary(duration)
    print "\n",
          Paint["Summary", :bold],
          "\n",
          "There was a total of #{@method_call_count} method call(s).",
          "\n",
          "#{@c_call_count} (#{method_call_average(@c_call_count)}%) ",
          "method calls were to methods implemented in C.",
          "\n",
          "#{@rb_call_count} (#{method_call_average(@rb_call_count)}%) ",
          "method calls were to methods implemented in Ruby.",
          "\n",
          "The trace took #{duration.round(2)}s.",
          "\n"
  end

  private

  def method_call_average(count)
    (count / @method_call_count.to_f).round(2) * 100
  end
end