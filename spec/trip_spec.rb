# frozen_string_literal: true

require_relative "setup"

class Trip::Planet
  def initialize(name)
    @name = name
  end

  def echo(message)
    message
  end
end

RSpec.describe Trip do
  subject(:trip) do
    Trip.new(%i[call return]) {
      Trip::Planet.new("earth").echo("ping")
    }
  end

  describe "#initialize" do
    context "when an argument is not given" do
      subject(:trip) { Trip.new }
      it { expect { trip }.to raise_error(ArgumentError) }
    end
  end

  describe "#start" do
    subject { trip.start }

    context "when returning an event" do
      it { is_expected.to be_instance_of(Trip::Event) }
    end

    context "when the pause predicate returns false" do
      before { trip.pause_when { false } }
      it { is_expected.to be_nil }
    end
  end

  describe "#pause_when" do
    context "when an argument is not given" do
      subject(:pause_when) { trip.pause_when }
      it { expect { pause_when }.to raise_error(ArgumentError) }
    end

    context "when a block is given" do
      subject { trip.pauser }
      before { trip.pause_when {} }
      it { is_expected.to be_instance_of(Proc) }
    end

    context "when given a callable" do
      subject { trip.pauser }
      before { trip.pause_when(callable) }
      let(:callable) { proc {} }
      it { is_expected.to eq(callable) }
    end

    context "when an exception is raised" do
      subject(:start) { trip.start }
      before { trip.pause_when { raise } }
      it { expect { start }.to raise_error(Trip::PauseError) }
    end

    context "when given an exception's cause" do
      subject do
        trip.start
      rescue Trip::PauseError => ex
        ex.cause.message
      end
      before { trip.pause_when { raise "from spec" } }
      it { is_expected.to eq("from spec") }
    end
  end

  describe "#to_a" do
    context "when counting the number of returned events" do
      subject { trip.to_a.size }
      it { is_expected.to eq(4) }
    end
  end
end
