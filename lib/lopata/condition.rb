module Lopata
  # @private
  class Condition
    attr_reader :condition, :positive
    def initialize(condition, positive: true)
      @condition, @positive = condition, positive
    end

    alias positive? positive

    def match?(scenario)
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

  end
end