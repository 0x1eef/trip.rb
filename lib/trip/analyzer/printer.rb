module Trip::Analyzer::Printer
  def print_about(io)
    io.print Paint["trip.rb", :bold], " (v#{Trip::VERSION})",
            "\n",
            "Homepage https://github.com/0x1eef/trip.rb#readme",
            "\n"
  end

  def print_header_row(io, precision)
    io.print Paint["Path".ljust(30), :bold, :black, :yellow],
             Paint["Event".ljust(10), :bold, :black, :yellow],
             Paint["Method".ljust(50 + precision), :bold, :black, :yellow],
             Paint["Time".ljust(10), :bold, :black, :yellow]
  end

  def print_trace(io, stacktrace_io, precision)
    io.print "\n\n"
    print_header_row(io, precision)
    io.print "\n", stacktrace_io.string
  end

  def print_event(stacktrace_io, event, indent_by, duration, precision)
    stacktrace_io.print event_path(event).ljust(30),
                        Paint[event.name.ljust(8), :green],
                        " " * indent_by,
                        Paint["-> ", :blue],
                        event.signature.ljust((49 + precision) - indent_by),
                        duration ? "#{duration.round(precision)}s" : "",
                        "\n"
  end

  def print_summary(io, duration, precision)
    io.print "\n",
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
             "The trace took #{duration.round(precision)}s.",
             "\n"
  end

  private

  def method_call_average(count)
    ((count / @method_call_count.to_f) * 100).round(2)
  end
end
