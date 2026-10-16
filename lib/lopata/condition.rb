module Lopata
  # @private
  class Condition
    attr_reader :condition, :positive, :dynamic
    def initialize(condition, positive: true)
      @condition, @positive = condition, positive
      @dynamic = @condition.is_a?(Proc)
    end

    alias positive? positive
    alias dynamic? dynamic

    # Combine conditions: the result matches when all the given conditions match.
    def self.combine(*conditions)
      conditions = conditions.compact
      return conditions.first if conditions.length <= 1
      CombinedCondition.new(conditions)
    end

    # Match scenario on build-time. 
    def match?(scenario)
      # dynamic steps match scenario in build-time: will be verified later
      return true if dynamic?  
      matched = match_metadata?(scenario)
      positive? ? matched : !matched
    end

    def match_metadata?(scenario)
      metadata = scenario.metadata
      case condition
      when Hash
        condition.keys.all? do |k| 
          if condition[k].is_a? Array
            condition[k].include?(metadata[k])
          else
            metadata[k] == condition[k]
          end
        end
      when Array
        condition.map { |key| metadata[key] }.all?
      when TrueClass, FalseClass
        condition
      else
        metadata[condition]
      end
    end

    def match_dynamic?(scenario_runtime)
      return false unless dynamic?
      matched = scenario_runtime.instance_exec(&condition)
      positive? ? matched : !matched
    end
  end

  # @private
  # All the conditions must match.
  class CombinedCondition
    attr_reader :conditions, :dynamic

    def initialize(conditions)
      @conditions = conditions
      @dynamic = conditions.any?(&:dynamic?)
    end

    alias dynamic? dynamic

    def match?(scenario)
      conditions.all? { |c| c.match?(scenario) }
    end

    def match_dynamic?(scenario_runtime)
      return false unless dynamic?
      # Static conditions are verified on build-time, so check dynamic ones only.
      conditions.select(&:dynamic?).all? { |c| c.match_dynamic?(scenario_runtime) }
    end
  end
end
