module ActionTimer
  class Action
  
    attr_accessor :owner
    attr_accessor :timer
  
    # timer:: Timer this action resides within
    # period:: amount of time between runs
    # once:: only run this action once
    # data:: data to pass to block
    # block:: block to be executed
    def initialize(hash, &block)
      raise ArgumentError.new('Period must be supplied') unless hash[:period]
      raise ArgumentError.new('Block must be provided') unless block_given?
      raise ArgumentError.new('Block must accept data value') if hash[:data] && block.arity == 0
      if((block.arity > 0 || block.arity < -1) && (!hash.has_key?(:data) || hash[:data].nil?))
        raise ArgumentError.new('Data must be supplied for block')
      end
      args = {:once => false, :data => nil, :owner => nil}.merge(hash)
      @period = args[:period].to_f
      @block = block
      @data = args[:data]
      @once = args[:once]
      @timer = args[:timer]
      @completed = false
      @wait_remaining = @period
      @owner = args[:owner]
    end

    # t:: ActionTimer::Timer
    # Set timer for action to be associated with
    def timer=(t)
      raise ArgumentError.new('Expecting an ActionTimer::Timer') unless t.is_a?(ActionTimer::Timer)
      @timer = t
    end
    
    # o:: Object that added this action
    # Adds an owner for this action. Useful
    # for clearing all actions for a given
    # object from the timer
    def owner=(o)
      @owner = o
    end
    
    # amount:: amount of time that has passed
    # Decrement remaining wait time by given amount
    def tick(amount)
      amount = amount.to_f
      amount = 0 if amount < 0
      @wait_remaining = @wait_remaining - amount if @wait_remaining > 0
      @wait_remaining = 0 if @wait_remaining < 0
      @completed = true if @once && @wait_remaining <= 0
    end
    
    # Time remaning before Action is due
    def remaining
      @wait_remaining <= 0 ? 0 : @wait_remaining
    end
    
    # new_time:: new period
    # Resets the wait period between runs
    def reset_period(new_time)
      @period = new_time.to_f
      @wait_remaining = @period
      @completed = false
      @timer.wakeup unless @timer.nil?
    end
    
    # Action is ready to be destroyed
    def is_complete?
      @completed
    end
    
    # Used for scheduling with Timer. Resets the interval
    # and returns itself
    def schedule
      @wait_remaining = @period
      return self
    end

    # Is action due for execution
    def due?
      @wait_remaining <= 0
    end
    
    # Run the action
    def run
      @data.nil? ? @block.call : @block.call(*@data)
    end
  end
end