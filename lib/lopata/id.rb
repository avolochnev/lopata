module Lopata
  # @private
  module Id
    extend self

    def next(prefix = nil)
      id = "%d_%d" % [timestamp, seq_num]
      id = "%s_%s" % [prefix, id] if prefix
      id
    end

    def timestamp
      @timestamp ||= Time.now.strftime("%Y%m%d%H%M%S")
    end

    def seq_num
      @seq_num ||= 0
      @seq_num += 1
      @seq_num
    end
  end
end
