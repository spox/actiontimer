require 'test/unit'
require 'actiontimer'

class TimerTests < Test::Unit::TestCase
    def setup
        @timer = ActionTimer::Timer.new
    end

    # Simple test of basic repetitive action
    def test_basic
        result = 0
        @timer.add(2){ result += 1 }
        sleep(5)
        assert_equal(2, result)
    end

    # Check the the running? method properly reports
    def test_running
        @timer.add(1){ 1 + 1}
        assert(@timer.running?)
        @timer.pause
        assert(!@timer.running?)
        @timer.start
        assert(@timer.running?)
        @timer.stop
        assert(!@timer.running?)
    end

    # Check that a single iterative action is only
    # completed once
    def test_once
        result = 0
        @timer.add(1, true){ result += 1 }
        sleep(3)
        assert_equal(1, result)
    end

    # Check that timer can be paused and restarted
    # without registered actions being effected
    def test_pause
        result = 0
        @timer.add(1){ result += 1 }
        sleep(3.1)
        @timer.pause
        sleep(2)
        @timer.start
        sleep(2.1)
        assert_equal(5, result)
    end

    # Check that data can be passed to the block
    # properly when created
    def test_data
        result = 0
        @timer.add(1, true, 3){|a| result = a}
        sleep(2)
        assert_equal(3, result)
        @timer.add(1, true, [3,4,['foobar']]){|a,b,c| result = [b,a,c]}
        sleep(2)
        assert_equal(4, result[0])
        assert_equal(3, result[1])
        assert(result[2].is_a?(Array))
    end

    # Check that the timer's auto starting mechanism
    # can be disabled
    def test_auto_start
        timer = ActionTimer::Timer.new(:auto_start => false)
        timer.add(1){ 1+1 }
        assert(!timer.running?)
        timer.start
        assert(timer.running?)
    end

    # Check that the actions can be cleared out of the
    # timer and the timer is still left in a "running"
    # state.
    def test_clear
        result = 0
        @timer.add(1){ result += 1 }
        sleep(3)
        @timer.clear
        sleep(2)
        assert_equal(2, result)
        assert(@timer.running?)
    end

    # Check that the timer throws an exception when it
    # is instructed to wakeup while not running
    def test_wakeup
        @timer.stop
        assert_raise(ActionTimer::NotRunning){ @timer.wakeup }
    end

    # Check that the timer throws an exception when it
    # is instructed to start but is already running
    def test_start
        assert_raise(ActionTimer::AlreadyRunning){ @timer.start }
    end

    # Check that multiple actions can be added at once
    def test_mass_add
        result = 0
        actions = []
        actions << ActionTimer::Action.new(@timer, 1){ result += 1}
        actions << ActionTimer::Action.new(@timer, 3){ result += 1}
        actions << ActionTimer::Action.new(@timer, 5){ result += 1}
        @timer.mass_add(actions)
        sleep(5.3)
        assert_equal(7, result)
    end

    # Check that an action can be properly removed from
    # the timer
    def test_remove
        result = 0
        action = @timer.add(1){result += 1}
        sleep(2.1)
        @timer.remove(action)
        sleep(2)
        assert_equal(2, result)
    end

    # Check that an action's period can be dynamically
    # reset
    def test_action_reset
        result = 0
        action = @timer.add(1){ result += 1}
        sleep(2.1)
        action.reset_period(3)
        sleep(3.1)
        assert_equal(result, 3)
    end
end