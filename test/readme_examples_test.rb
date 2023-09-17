require_relative "setup"

class Trip::ReadmeExamplesTest < Test::Unit::TestCase
  include Test::Cmd

  def test_1_what_is_a_concurrent_tracer
    assert_equal "Ruby is cool.\n",
                 cmd(example("1_what_is_a_concurrent_tracer.rb")).stdout
  end

  def test_2_filter_events
    assert_equal "call add\n70\nreturn add\n",
                 cmd(example("2_filter_events.rb")).stdout
  end

  def test_3_pause_when
    assert_equal "Foo class opened\nBar class opened\nBaz class opened\n",
                 cmd(example("3_trip_pause_when.rb")).stdout
  end

  private

  def example(filename)
    File.join(Dir.getwd, "share", "trip.rb", "examples", filename)
  end
end
