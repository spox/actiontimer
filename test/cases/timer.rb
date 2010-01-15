require 'test/unit'
require 'actiontimer'

class TimerTests < Test::Unit::TestCase
    def setup
        @timer = ActionTimer::Timer.new
    end
    
    def teardown
    end

    def test_add_bad
        assert_raise(ArgumentError) do
            @timer.add{true}
        end
        assert_raise(ArgumentError) do
            @timer.add(1){true}
        end
        assert_raise(ArgumentError) do
            @timer.add(:period => 1)
        end
        if(RUBY_VERSION > "1.9.0")
            assert_raise(ArgumentError) do
                @timer.add(:period => 1, :data => 2){true}
            end
        end
    end

    def test_add
        output = []
        action = @timer.add(:period => 0.1){true}
        assert_kind_of(ActionTimer::Action, action)
        sleep(0.01)
        assert_equal(1, @timer.actions.size)
        assert(@timer.registered?(action))
        @timer.add(:period => 0.1, :once => true, :data => :foo){|x| output << x }
        sleep(0.01)
        assert_equal(2, @timer.actions.size)
        sleep(0.14)
        assert_equal(:foo, output.pop)
        assert_equal(1, @timer.actions.size)
    end

    def test_register
        output = []
        action = ActionTimer::Action.new(:period => 0.01){output << :action}
        @timer.register(action)
        sleep(0.113)
        @timer.pause
        assert_equal(10, output.size)
        assert_equal(1, @timer.actions.size)
        assert(@timer.registered?(action))
        @timer.clear
        assert(@timer.actions.empty?)
        @timer.start
        output.clear
        actions = [action]
        actions << ActionTimer::Action.new(:period => 0.02){output << :fubar}
        @timer.register(actions)
        sleep(0.051)
        @timer.pause
        assert_equal(7, output.size)
        assert(output.include?(:fubar))
        assert_equal(2, @timer.actions.size)
        actions.each{|x| assert(@timer.registered?(x)) }
    end

    def test_remove
        output = []
        action = ActionTimer::Action.new(:period => 0.01){output << :action}
        @timer.register(action)
        sleep(0.029)
        @timer.remove(action)
        assert_equal(2, output.size)
        assert(@timer.actions.empty?)
        output.clear
        assert(output.empty?)
        action = @timer.add(:period => 0.01){output << :action}
        sleep(0.021)
        @timer.remove(action)
        assert(!@timer.registered?(action))
        assert(2, output.size)
    end

end