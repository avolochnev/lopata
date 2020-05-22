module Lopata
  module RSpec
    module DSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def action *contexts, &block
          contexts.each do |context|
            if context.is_a?(Proc)
              action(&context)
            else
              verify context
            end
          end
          before(:all, &block) if block_given?
        end

        def setup *contexts, &block
          root_setup = false
          unless @doing_setup
            root_setup = true
            @doing_setup = true
          end
          action *contexts, &block
          if root_setup
            # action Config.after_setup if Config.after_setup
            @doing_setup = false
          end
        end

        def teardown &block
          after(:all, &block) if block_given?
        end
      end
    end
  end
end