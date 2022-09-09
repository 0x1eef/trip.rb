require_relative "setup"

class Trip::Planet
  def initialize(name)
    @name = name
  end

  def echo message
    message
  end
end

RSpec.describe Trip do
  let(:planet) do
    Trip::Planet.new "earth"
  end

  subject(:trip) do
    Trip.new { planet.echo("ping") }
  end

  describe "#initialize" do
    it "raises an ArgumentError without a block" do
      expect { Trip.new }.to raise_error(ArgumentError)
    end
  end

  describe "#start" do
    it "returns an instance of Trip::Event" do
      expect(Trip::Event === trip.start).to be(true)
    end

    it "returns nil with a false pause predicate" do
      trip.pause_when { false }
      expect(trip.start).to be(nil)
    end
  end

  describe "#pause_when" do
    it "raises an ArgumentError" do
      expect { trip.pause_when }.to raise_error(ArgumentError)
    end

    it "accepts a block" do
      expect(trip.pause_when {})
      expect(trip.pauser).to be_instance_of(Proc)
    end

    it "accepts an object who implements #call" do
      obj = proc {}
      trip.pause_when(obj)
      expect(trip.pauser).to eq(obj)
    end

    it "causes the raise of Trip::PauseError" do
      trip.pause_when { raise }
      expect { trip.start }.to raise_error(Trip::PauseError)
    end
  end
end
