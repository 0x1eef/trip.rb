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
    stdout = cmd(example("3_trip_pause_when.rb")).stdout
    assert_equal(<<-STDOUT, stdout.each_line.take(9).join($\))
Event     Location       Method
call      http.rb:470    Net::HTTP.get_response
c_call    http.rb:480    URI::HTTPS#port
c_return  http.rb:480    URI::HTTPS#port
c_call    http.rb:481    URI::HTTPS#scheme
c_return  http.rb:481    URI::HTTPS#scheme
c_call    http.rb:481    String#==
c_return  http.rb:481    String#==
call      http.rb:668    Net::HTTP.start
    STDOUT
  end

  def test_4_analysis_count_requires
    stdout = cmd(example("4_analysis_count_requires.rb")).stdout
    assert_equal(<<-STDOUT, stdout.each_line.take(12).join($\))
166
pry
pry/version
pry/last_exception
pry/forwardable
forwardable
forwardable/impl
pry/helpers/base_helpers
pry/helpers/documentation_helpers
pry/helpers
pry/helpers/base_helpers
pry/helpers/options_helpers
    STDOUT
  end

  private

  def example(filename)
    File.join(Dir.getwd, "share", "trip.rb", "examples", filename)
  end
end
