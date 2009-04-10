require 'actionpool'
['Action', 'Exceptions', 'LogHelper'].each{|f| require "actiontimer/#{f}"}

module ActionTimer
    class Timer
        # pool:: ActionPool for processing actions
        # Creates a new timer
        def initialize(pool=nil, logger=nil)
            @actions = []
            @new_actions = []
            @timer_thread = nil
            @stop_timer = false
            @add_lock = Mutex.new
            @awake_lock = Mutex.new
            @new_actions = Queue.new
            @pool = pool.nil? ? ActionPool.new : pool
            @logger = LogHelper.new(logger)
        end
        
        # Forcibly wakes the timer early
        def wakeup
            return unless @awake_lock.try_lock
            @timer_thread.wakeup
            @awake_lock.unlock
        end
        
        # period:: amount of time between runs
        # once:: only run this action once
        # data:: data to pass to block
        # owner:: owner of Action
        # func:: block to be executed
        # Add a new action to block
        def add(period, once=false, data=nil, owner=nil, &func)
            action = Action.new(self, period, once, data, &func)
            action.owner = owner unless owner.nil?
            @add_lock.synchronize{ @new_actions << action }
            wakeup
            return action
        end
        
        # actions:: Array of actions
        # Add multiple Actions to the timer at once
        def mass_add(actions)
            raise Exceptions::InvalidType.new(Array, actions.class) unless actions.is_a?(Array)
            actions.each do |action|
                raise Exceptions::InvalidType.new(ActionTimer::Action, action.class) unless action.is_a?(Action)
            end
            @add_lock.synchronize{ @new_actions = @new_actions + actions }
            wakeup
        end
        
        # action:: Action to remove from timer
        # Remove given action from timer
        def remove(action)
            raise Exceptions::InvalidType.new(ActionTimer::Action, action.class) unless action.is_a?(Action)
            @actions.delete(action)
            wakeup
        end
        
        # Start the timer
        def start
            raise Exceptions::AlreadyRunning.new unless @timer_thread.nil?
            @timer_thread = Thread.new do
                begin
                    until @stop_timer do
                        to_sleep = get_min_sleep
                        if((to_sleep.nil? || to_sleep > 0) && @new_actions.empty?)
                            @awake_lock.unlock
                            actual_sleep = to_sleep.nil? ? sleep : sleep(to_sleep)
                            @awake_lock.lock
                        else
                            actual_sleep = 0
                        end
                        tick(actual_sleep)
                        add_waiting_actions
                    end
                rescue Object => boom
                    @logger.fatal("Timer encountered an unexpected error: #{boom}\n#{boom.backtrace.join("\n")}")
                end
            end
        end
        
        # Stop the timer
        def stop
            @stop_timer = true
            wakeup
            @timer_thread.join
        end
        
        # owner:: owner actions to remove
        # Clears timer of actions. If an owner is supplied
        # only actions owned by owner will be removed
        def clear(owner=nil)
            if(owner.nil?)
                @actions.clear
                @new_actions.clear
            else
                @actions.each{|a| @actions.delete(a) if a.owner == owner}
            end
            wakeup
        end
        
        private
        
        def get_min_sleep
            min = @actions.map{|a|a.remaining}.sort[0]
            unless(min.nil? || min > 0)
                @actions.each{|a|@actions.delete(a) if a.remaining == 0} # kill stuck actions
                min = get_min_sleep
            end
            return min
        end
        
        def add_waiting_actions
            @add_lock.synchronize do
                @actions = @actions + @new_actions
                @new_actions.clear
            end
        end
        
        def tick(time_passed)
            @actions.each do |action|
                action.tick(time_passed)
                if(action.due?)
                    remove(action) if action.is_complete?
                    action = action.schedule
                    @pool.process do
                        begin
                            action.run
                        rescue Object => boom
                            @logger.error("Timer caught an error while running action: #{boom}\n#{boom.backtrace.join("\n")}")
                        end
                    end
                end
            end
        end
        
    end
end