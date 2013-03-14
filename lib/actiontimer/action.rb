module ActionTimer
  class Action
  
    attr_accessor :owner
    attr_accessor :timer
    attr_reader :period
    attr_reader :once
  
    # timer:: Timer this action resides within
    # period:: amount of time between runs
    # once:: only run this action once
    # data:: data to pass to block
    # block:: block to be executed
    def initialize(hash={}, &block)
      raise ArgumentError.new('Timer must be provided') unless hash[:timer]
      raise ArgumentError.new('Period must be provided') unless hash[:period]
      raise ArgumentError.new('Block must be provided') unless block_given?
      raise ArgumentError.new('Block must accept data value') if hash[:data] && block.arity == 0
      if((block.arity > 0 || block.arity < -1) && (!hash.has_key?(:data) || hash[:data].nil?))
        raise ArgumentError.new('Data must be supplied for block')
      end
      args = {:once => false, :data => nil, :owner => nil}.merge(hash)
      @block = block
      @timer = args[:timer]
      @data = args[:data]
      @owner = args[:owner]
      @period = args[:period]
      @once = args.has_key?(:once) ? args[:once] : true
    end

    # o:: Object that added this action
    # Adds an owner for this action. Useful
    # for clearing all actions for a given
    # object from the timer
    def owner=(o)
      @owner = o
    end

    def complete?
      !@timer.actions.include?(self)
    end

    # Run the action
    def run
      result = @data.nil? ? @block.call : @block.call(*@data)
      @timer.remove(self) if @once
      result
    end

    def cancel
      @timer.remove(self)
    end
  end
end
