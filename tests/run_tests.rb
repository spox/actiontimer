require 'test/unit'
require 'actiontimer'

class TimerTests < Test::Unit::TestCase
    def setup
        @timer = ActionTimer::Timer.new
    end
    
    def test_basic
        result = 0
        @timer.add(2){ result += 1 }
        sleep(5)
        assert_equal(2, result)
    end
    
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
    
    def test_once
        result = 0
        @timer.add(1, true){ result += 1 }
        sleep(3)
        assert_equal(1, result)
    end
    
    def test_pause
        result = 0
        @timer.add(1){ result += 1 }
        sleep(3)
        @timer.pause
        sleep(2)
        @timer.start
        sleep(2)
        assert_equal(4, result)
    end
    
    def test_data
        result = 0
        @timer.add(1, true, 3){|a| result = a}
        sleep(2)
        assert_equal(3, result)
    end
    
    def test_auto_start
        timer = ActionTimer::Timer.new(:auto_start => false)
        timer.add(1){ 1+1 }
        assert(!timer.running?)
        timer.start
        assert(timer.running?)
    end
    
    def test_clear
        result = 0
        @timer.add(1){ result += 1 }
        sleep(3)
        @timer.clear
        sleep(2)
        assert_equal(2, result)
    end
    
    def test_wakeup
        @timer.stop
        assert_kind_of(ActionTimer::NotRunning, @timer.wakeup)
    end
    
    def test_start
        assert_kind_of(ActionTimer::AlreadyRunning, @timer.start)
    end
end