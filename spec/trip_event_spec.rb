# frozen_string_literal: true

require_relative "setup"

class Trip::Math
  def self.add(x, y)
    sum = x + y
    sum.to_s
  end
end

RSpec.describe Trip::Event do
  let(:trip) do
    Trip.new(%i[call return]) { Trip::Math.add(2, 5) }
  end

  describe "#name" do
    describe "Ruby methods" do
      context "when an event represents a method call" do
        subject { trip.start.name }
        it { is_expected.to eq(:call) }
      end

      context "when an event represents a method return" do
        subject { trip.resume.name }
        before { trip.start }
        it { is_expected.to eq(:return) }
      end
    end

    describe "C methods" do
      subject(:trip) { Trip.new(%i[c_call c_return]) { Kernel.print("") } }
      before { trip.pause_when { _1.self == Kernel } }

      context "when an event represents a method call" do
        subject { trip.start.name }
        it { is_expected.to eq(:c_call) }
      end

      context "when an event represents a method return" do
        subject { trip.resume.name }
        before { trip.start }
        it { is_expected.to eq(:c_return) }
      end
    end
  end

  describe "#path" do
    subject { trip.start.path }
    it { is_expected.to eq(__FILE__) }
  end

  describe "#lineno" do
    subject { trip.start.lineno }
    it { is_expected.to eq(6) }
  end

  describe "#binding" do
    context "when altering the context of a Binding" do
      subject { binding.eval("sum") }
      let(:binding) { trip.start.binding }
      before { binding.eval("x = 4").then { trip.resume } }
      it { is_expected.to eq(9) }
    end
  end

  describe "#__binding__" do
    subject { trip.start.__binding__.eval("self") }
    it { is_expected.to be_instance_of(Trip::Event) }
  end

  describe "#inspect" do
    subject { trip.start.inspect }
    it { is_expected.to be_instance_of(String) }
  end
end
