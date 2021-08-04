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

  let(:trip) do
    Trip.new { planet.echo("ping") }
  end

  after do
    trip.stop unless trip.finished?
  end

  describe "#initialize" do
    it "raises an ArgumentError without a block" do
      expect {
        Trip.new
      }.to raise_error(ArgumentError)
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

    it "raises Trip::InProgressError" do
      trip.start
      expect {
        trip.start
      }.to raise_error(Trip::InProgressError)
    end
  end

  describe "#sleeping?" do
    it "returns true" do
      trip.start
      expect(trip.sleeping?).to be(true)
    end

    it "returns false" do
      trip.start
      trip.resume while trip.resume
      expect(trip).to_not be_sleeping
    end
  end

  describe "#started?" do
    it "returns true" do
      trip.start
      expect(trip).to be_started
    end

    it "returns false" do
      expect(trip).to_not be_started
    end
  end

  describe "#resume" do
    it "raises Trip::NotStartedError" do
      expect {
        trip.resume
      }.to raise_error(Trip::NotStartedError)
    end
  end

  describe "#pause_when" do
    it "raises an ArgumentError" do
      expect { trip.pause_when }.to raise_error(ArgumentError)
    end

    it "accepts a block" do
      expect(trip.pause_when {})
      expect(trip.instance_variable_get(:@pause_when)).to be_instance_of(Proc)
    end

    it "accepts an object who implements #call" do
      obj = proc {}
      trip.pause_when(obj)
      expect(trip.instance_variable_get(:@pause_when)).to eq(obj)
    end

    it "causes the raise of Trip::PauseError" do
      trip.pause_when { raise }
      expect { trip.start }.to raise_error(Trip::PauseError)
    end
  end

  describe "#finished?" do
    it "returns true" do
      trip.start
      trip.resume while trip.resume
      expect(trip).to be_finished
    end

    it "returns false" do
      trip.start
      expect(trip).to_not be_finished
    end

    it "returns nil" do
      expect(trip.finished?).to be(nil)
    end
  end

  describe "#running?" do
    it "returns false" do
      trip.start
      trip.resume while trip.resume
      expect(trip).to_not be_running
    end

    it "returns nil" do
      expect(trip.running?).to be(nil)
    end
  end
end
