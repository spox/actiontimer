require 'actionpool'
['Action', 'Exceptions'].each{|f| require "actiontimer/#{f}"}

module ActionTimer
  class Timer
    # pool:: ActionPool for processing actions
    # Creates a new timer
    # Argument hash: {:pool, :logger, :auto_start}
    def initialize(args={}, extra=nil)
      auto_start = true
      @delta = nil
      if(args.is_a?(Hash))
        @pool = args[:pool] ? args[:pool] : ActionPool::Pool.new
        @logger = args[:logger] && args[:logger].is_a?(Logger) ? args[:logger] : Logger.new(nil)
        auto_start = args.has_key?(:auto_start) ? args[:auto_start] : true
        @delta = args[:delta] ? args[:delta].to_f : nil
      else
        @pool = args.is_a?(ActionPool::Pool) ? args : ActionPool::Pool.new
        @logger = extra && extra.is_a?(Logger) ? extra : Logger.new(nil)
      end
      @actions = []
      @new_actions = []
      @timer_thread = nil
      @stop_timer = false
      @add_lock = Splib::Monitor.new
      @awake_lock = Splib::Monitor.new
      @sleeper = Splib::Monitor.new
      @respond_to = Thread.current
      start if auto_start
    end
    
    # Forcibly wakes the timer early
    def wakeup
      raise NotRunning.new unless running?
      if(@sleeper.waiters > 0)
        @sleeper.signal
      else
        @timer_thread.wakeup if @timer_thread.alive? && @timer_thread.stop?
      end
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
      @add_lock.synchronize{ @new_actions << action }
      wakeup if running?
      action
    end
    
    # actions:: Array of actions or single ActionTimer::Action
    # Add single or multiple Actions to the timer at once
    def register(action)
      if(action.is_a?(Array))
        if(action.find{|x|x.is_a?(Action)}.nil?)
          raise ArgumentError.new('Array contains non ActionTimer::Action objects')
        end
      else
        raise ArgumentError.new('Expecting an ActionTimer::Action object') unless action.is_a?(Action)
        action = [action]
      end
      @add_lock.synchronize{ @new_actions = @new_actions + action }
      wakeup if running?
    end
    
    # action:: Action to remove from timer
    # Remove given action from timer
    def remove(action)
      raise ArgumentError.new('Expecting an action') unless action.is_a?(Action)
      @actions.delete(action)
      wakeup if running?
    end
    
    # Start the timer
    def start
      raise AlreadyRunning.new unless @timer_thread.nil?
      @stop_timer = false
      @timer_thread = Thread.new do
        begin
          until @stop_timer do
            to_sleep = get_min_sleep
            if((to_sleep.nil? || to_sleep > 0) && @new_actions.empty?)
              @awake_lock.unlock if @awake_lock.locked?
              start = Time.now.to_f
              to_sleep.nil? ? @sleeper.wait : sleep(to_sleep)
              actual_sleep = Time.now.to_f - start
              if(@delta && to_sleep && actual_sleep.within_delta?(:expected => to_sleep, :delta => @delta))
                actual_sleep = to_sleep
              end
              @awake_lock.lock
            else
              actual_sleep = 0
            end
            tick(actual_sleep)
            add_waiting_actions
          end
        rescue Object => boom
          @timer_thread = nil
          clean_actions
          @logger.fatal("Timer encountered an unexpected error and is shutting down: #{boom}\n#{boom.backtrace.join("\n")}")
          @respond_to.raise boom
        end
      end
    end
    
    # Pause the timer in its current state.
    def pause
      @stop_timer = true
      if(running?)
        wakeup
        @timer_thread.join
      end
      @timer_thread = nil
    end

    # Stop the timer. Unlike pause, this will completely
    # stop the timer and remove all actions from the timer
    def stop
      @stop_timer = true
      if(running?)
        wakeup
        clean_actions
        @timer_thread.join
      end
      @timer_thread = nil
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
      wakeup if running?
    end
    
    # Is timer currently running?
    def running?
      !@timer_thread.nil?
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
    
    private
    
    def get_min_sleep
      min = @actions.min{|a,b|a.remaining <=> b.remaining}
      min.remaining if min
    end
    
    def add_waiting_actions
      @add_lock.synchronize do
        @new_actions.each{|a|a.timer = self}
        @actions = @actions + @new_actions
        @new_actions.clear
      end
    end
    
    def tick(time_passed)
      @actions.each do |action|
        action.tick(time_passed)
        if(action.due?)
          @actions.delete(action) if action.is_complete?
          action = action.schedule
          @pool.process do
            begin
              action.run
            rescue StandardError => boom
              @logger.error("Timer caught an error while running action: #{boom}\n#{boom.backtrace.join("\n")}")
            end
          end
        end
      end
    end
    
    def clean_actions
      @actions.clear
      @new_actions.clear
    end
    
  end
end