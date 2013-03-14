require 'timers'
require 'actionpool'
require 'actiontimer/action'

module ActionTimer
  class Timer
    class Wakeup < StandardError
    end

    # Creates a new timer
    # Argument hash: {:logger, :pool}
    def initialize(args={}, extra=nil)
      @pool = args[:pool] || ActionPool::Pool.new
      if(args.is_a?(Hash))
        @logger = args[:logger] && args[:logger].is_a?(Logger) ? args[:logger] : Logger.new(nil)
      else
        @logger = extra && extra.is_a?(Logger) ? extra : Logger.new(nil)
      end
      @timers = Timers.new
      @actions = {}
      @paused = false
      @run = true
      @thread = timer_thread
    end
    
    # period:: amount of time between runs
    # once:: only run this action once
    # data:: data to pass to block
    # owner:: owner of Action
    # func:: block to be executed
    # Add a new action to block
    def add(hash, &func)
      raise ArgumentError.new('Expecting hash of arguments') unless hash.is_a?(Hash)
      raise ArgumentError.new('A period must be provided for timed action') unless hash[:period]
      raise ArgumentError.new('Block must be provided') unless block_given?
      raise ArgumentError.new('Block must accept data value') if hash[:data] && func.arity == 0
      args = {:once => false, :data => nil, :owner => nil}.merge(hash)
      action = Action.new(args.merge(:timer => self), &func)
      register(action)
    end

    def register(actions)
      res = [actions].flatten.map do |action|
        timer = Timers::Timer.new(@timers, action.period, !action.once) do
          @pool.queue do
            action.run
          end
        end
        @actions[action] = timer
        action
      end
      wakeup!
      res.size > 1 ? res : res.first
    end
    
    # action:: Action to remove from timer
    # Remove given action from timer
    def remove(action, wakeup=true)
      raise ArgumentError.new('Expecting an action') unless action.is_a?(Action)
      @actions.delete(action).cancel
      wakeup!
    end
    
    # Stop the timer. 
    def stop
      actions.keys.each do |action|
        remove(action, false)
      end
      wakeup!
    end 

    def pause
      @paused = true
      wakeup!
    end

    def unpause
      @paused = false
      wakeup!
    end

    # owner:: owner actions to remove
    # Clears timer of actions. If an owner is supplied
    # only actions owned by owner will be removed
    def clear(owner=nil)
      if(owner.nil?)
        stop
      else
        @actions.each do |action|
          if(action.owner == owner)
            @actions.delete(action).cancel
          end
        end
      end
      wakeup!
    end
    
    # action:: ActionTimer::Action
    # Is action currently in timer
    def registered?(action)
      @actions.include?(action)
    end

    # Actions registered with the timer
    def actions
      @actions.dup
    end

    def restart
      unless(@thread.status)
        @thread = timer_thread
      end
    end

    private

    def timer_thread
      Thread.new do
        while(@run)
          begin
            if(@timers.empty? || @paused)
              sleep
            else
              @timers.wait
            end
          rescue Wakeup
            # okay
          rescue Exception => e
            puts "Ack: #{e}"
          end
        end
      end
    end

    def wakeup!
      Thread.pass
      @thread.raise Wakeup.new
    end
    
  end
end
