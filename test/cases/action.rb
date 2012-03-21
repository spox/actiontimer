require 'test/unit'
require 'actiontimer'

class ActionTests < Test::Unit::TestCase
  def setup
    @timer = ActionTimer::Timer.new
  end
  def teardown
  end

  def test_create
    assert_raise(ArgumentError) do
      action = ActionTimer::Action.new(:timer => @timer){true}
    end
    assert_raise(ArgumentError) do
      action = ActionTimer::Action.new(:timer => @timer, :period => 1){|x|true}
    end
    assert_raise(ArgumentError) do
      action = ActionTimer::Action.new(:timer => @timer, :period => 1, :data => 1)
    end
    if(RUBY_VERSION > "1.9.0")
      assert_raise(ArgumentError) do
        action = ActionTimer::Action.new(:timer => @timer, :period => 1, :data => 1){true}
      end
    end
    assert_kind_of(ActionTimer::Action, ActionTimer::Action.new(:timer => @timer, :period => 1){true})
    assert_kind_of(ActionTimer::Action, ActionTimer::Action.new(:timer => @timer, :period => 1, :once => true){true})
    assert_kind_of(ActionTimer::Action, ActionTimer::Action.new(:timer => @timer, :period => 1, :once => false){true})
  end

  def test_timer
    mytimer = ActionTimer::Timer.new
    action = ActionTimer::Action.new(:timer => @timer, :period => 1){true}
    assert_equal(@timer, action.timer)
    action.timer = mytimer
    assert_equal(mytimer, action.timer)
  end
  
  def test_owner
    object = Object.new
    action = ActionTimer::Action.new(:timer => @timer, :period => 1, :owner => object){true}
    assert_equal(object, action.owner)
    other_object = Object.new
    action.owner = other_object
    assert_equal(other_object, action.owner)
    action.owner = object
    assert_equal(object, action.owner)
  end

  def test_tick
    action = ActionTimer::Action.new(:timer => @timer, :period => 2){true}
    action.tick(1)
    assert_equal(1, action.remaining)
    action.tick(0.1)
    assert_equal(0.9, action.remaining)
    action.tick(0.11)
    assert_equal(0.79, action.remaining)
  end

  def test_reset_period
    action = ActionTimer::Action.new(:timer => @timer, :period => 2){true}
    action.tick(1)
    assert_equal(1, action.remaining)
    action.reset_period(3)
    assert_equal(3, action.remaining)
    action.tick(3)
    assert_equal(0, action.remaining)
    assert(!action.is_complete?)
  end

  def test_complete
    action = ActionTimer::Action.new(:timer => @timer, :period => 2, :once => true){true}
    action.tick(2)
    assert_equal(0, action.remaining)
    assert(action.is_complete?)
  end

  def test_schedule
    action = ActionTimer::Action.new(:timer => @timer, :period => 2){true}
    action.tick(1)
    assert_equal(1, action.remaining)
    assert_equal(action, action.schedule)
    assert_equal(2, action.remaining)
  end

  def test_due
    action = ActionTimer::Action.new(:timer => @timer, :period => 2){true}
    assert(!action.due?)
    action.tick(2)
    assert(action.due?)
  end

  def test_run_noargs
    a = false
    action = ActionTimer::Action.new(:timer => @timer, :period => 2){ a = true }
    assert(!a)
    action.run
    assert(a)
  end

  def test_run_args
    a = []
    action = ActionTimer::Action.new(:timer => @timer, :period => 2, :data => [1,2,[3]]) do |b,c,d|
      a << b
      a << c
      a << d
    end
    action.run
    assert_kind_of(Array, a.pop)
    assert_equal(2, a.pop)
    assert_equal(1, a.pop)
    assert(a.empty?)
    action = ActionTimer::Action.new(:timer => @timer, :period => 2, :data => [1,2,[3]]) do |*b|
      a = b
    end
    action.run
    assert_kind_of(Array, a)
    assert_kind_of(Array, a.pop)
    assert_equal(2, a.pop)
    assert_equal(1, a.pop)
    assert(a.empty?)    
    action = ActionTimer::Action.new(:timer => @timer, :period => 2, :data => :foo) do |b|
      a = b
    end
    action.run
    assert_equal(:foo, a)
  end
end