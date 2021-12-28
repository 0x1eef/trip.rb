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

  after do
    trip.stop unless trip.finished?
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

    it "raises Trip::InProgressError" do
      trip.start
      expect { trip.start }.to raise_error(Trip::InProgressError)
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
    it "starts a trace if one has not already been started" do
      expect(trip).to_not be_started
      trip.resume
      expect(trip).to be_started
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
    context "after the tracer has finished" do
      before { trip.resume while trip.resume }

      it { is_expected.to be_finished }
    end

    context "before the tracer has finished" do
      before { trip.start }

      it { is_expected.to_not be_finished }
    end

    context "before the tracer has started" do
      it { is_expected.to_not be_finished }
    end
  end

  describe "#running?" do
    context "after the tracer has finished" do
      before { trip.resume while trip.resume }

      it { is_expected.to_not be_running }
    end

    context "before the tracer has started" do
      it { is_expected.to_not be_running }
    end
  end
end
