require_relative "setup"

module Test::Cmd
  require "tempfile"
  class Result
    attr_reader :stdout, :stderr
    def initialize(stdout, stderr)
      @stdout = stdout.tap(&:rewind).read
      @stderr = stderr.tap(&:rewind).read
    end
  end

  def cmd(cmd)
    out = Tempfile.new("cmd-stdout").tap(&:unlink)
    err = Tempfile.new("cmd-stderr").tap(&:unlink)
    Process.wait spawn(cmd, {err:, out:})
    Result.new(out, err)
  ensure
    out.close
    err.close
  end
end

class Trip::ReadmeExamplesTest < Test::Unit::TestCase
  include Test::Cmd

  def test_1_what_is_a_concurrent_tracer
    assert_equal "Ruby is cool.\n",
                 cmd("readme_examples/1_what_is_a_concurrent_tracer.rb").stdout
  end

  def test_2_filter_events
    assert_equal "call add\n70\nreturn add\n",
                 cmd("readme_examples/2_filter_events.rb").stdout
  end

  def test_3_pause_when
    assert_equal "Foo class opened\nBar class opened\nBaz class opened\n",
                 cmd("readme_examples/3_trip_pause_when.rb").stdout
  end
end
