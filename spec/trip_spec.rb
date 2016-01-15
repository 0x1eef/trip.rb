require_relative 'setup'
describe Trip do
  class Planet
    def initialize(name)
      @name = name
    end

    def echo message
      return message
    end
  end

  before do
    @planet = Planet.new 'earth'
    @trip   = Trip.new { @planet.echo('ping') }
  end

  after do
    @trip.stop if not @trip.finished?
  end

  describe '#initialize' do
    it 'raises an ArgumentError without a block' do
      assert_raises(ArgumentError) { Trip.new }
    end
  end

  describe '#start' do
    it 'returns an instance of Trip::Event' do
      assert Trip::Event === @trip.start
    end

    it 'returns nil with a false pause predicate' do
      @trip.pause_when { false }
      assert_equal nil, @trip.start
    end

    it 'raises Trip::InProgessError' do
      @trip.start
      assert_raises(Trip::InProgessError) { @trip.start }
    end
  end

  describe '#sleeping?' do
    it 'returns true' do
      @trip.start
      assert_equal true, @trip.sleeping?
    end

    it 'returns false' do
      @trip.start
      @trip.resume while @trip.resume
      assert_equal false, @trip.sleeping?
    end
  end

  describe '#started?' do
    it 'returns true' do
      @trip.start
      assert_equal true, @trip.started?
    end

    it 'returns false' do
      assert_equal false, @trip.started?
    end
  end

  describe '#resume' do
    it 'raises Trip::NotStartedError' do
      assert_raises(Trip::NotStartedError) { @trip.resume }
    end
  end

  describe '#pause_when' do
    it 'raises an ArgumentError' do
      assert_raises(ArgumentError) { @trip.pause_when }
    end

    it 'accepts a block' do
      assert_instance_of Proc, @trip.pause_when {}
    end

    it 'accepts an object who implements #call' do
      obj = Proc.new {}
      assert_equal obj, @trip.pause_when(obj)
    end

    it 'causes the raise of Trip::PauseError' do
      @trip.pause_when { raise }
      e = assert_raises(Trip::PauseError) { @trip.start }
      assert_instance_of RuntimeError, e.cause
    end
  end

  describe '#finished?' do
    it 'returns true' do
      @trip.start
      @trip.resume while @trip.resume
      assert_equal true, @trip.finished?
    end

    it 'returns false' do
      @trip.start
      assert_equal false, @trip.finished?
    end

    it 'returns nil' do
      assert_equal nil, @trip.finished?
    end
  end

  describe '#running?' do
    it 'returns false' do
      @trip.start
      @trip.resume while @trip.resume
      assert_equal false, @trip.running?
    end

    it 'returns nil' do
      assert_equal nil, @trip.running?
    end
  end
end
