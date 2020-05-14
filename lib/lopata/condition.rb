module Lopata
  class Condition
    attr_reader :condition, :positive
    def initialize(condition, positive: true)
      @condition, @positive = condition, positive
    end

    EMPTY = new({})

    alias positive? positive

    def match?(scenario)
      matched = match_metadata?(scenario)
      positive? ? matched : !matched
    end

    def match_metadata?(scenario)
      metadata = scenario.metadata
      case condition
      when Hash
        condition.keys.all? { |k| metadata[k] == condition[k] }
      when Array
        condition.map { |key| metadata[key] }.none?(&:nil?)
      else
        metadata[condition]
      end
    end

  end
end