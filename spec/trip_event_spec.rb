require_relative 'setup'
describe Trip::Event do
  class DummyClass
    def self.run(x,y)
      sum = x + y
    end
  end

  let(:trip) do
    Trip.new { DummyClass.run(2,5) }
  end

  after do
    trip.stop
  end

  describe '#type' do
    describe 'call and return of method implemented in Ruby' do
      it 'returns "call"' do
        event = trip.start
        assert_equal 'call', event.type
      end

      it 'returns "return"' do
        trip.start
        event = trip.resume
        assert_equal 'return', event.type
      end
    end

    describe 'call and return of method implemented in C' do
      let(:trip) do
        trip = Trip.new { Kernel.print '' }
        trip.pause_when { |event| event.from_module == Kernel and event.from_method == :print }
        trip
      end

      it 'returns "c-call"' do
        event = trip.start
        assert_equal 'c-call', event.type
      end

      it 'returns "c-return"' do
        trip.start
        event = trip.resume
        assert_equal 'c-return', event.type
      end
    end
  end

  describe '#from_module' do
    it 'returns the Module from where an event originated' do
      event = trip.start
      assert_equal DummyClass, event.from_module
    end
  end

  describe '#from_method' do
    it 'returns the type of the method where an event originated' do
      event = trip.start
      assert_equal :run, event.from_method
    end
  end

  describe '#file' do
    it 'returns __FILE__' do
      event = trip.start
      assert_equal __FILE__, event.file
    end
  end

  describe '#lineno' do
    it 'returns __LINE__' do
      event = trip.start
      assert_equal 4, event.lineno
    end
  end

  describe '#binding' do
    it 'returns a binding' do
      event = trip.start
      assert_instance_of Binding, event.binding
    end

    it 'changes value of "x"' do
      event = trip.start
      event.binding.eval('x = 4')
      event = trip.resume
      assert_equal 9, event.binding.eval('sum')
    end
  end

  describe '#__binding__' do
    it 'returns a binding for instance of Trip::Event' do
      event = trip.start
      assert_equal true, Trip::Event === event.__binding__.eval('self')
    end
  end

  describe '#inspect' do
    it 'returns a String' do
      event = trip.start
      assert_instance_of(String, event.inspect)
    end
  end
end
