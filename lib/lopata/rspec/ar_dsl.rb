module Lopata
  module RSpec
    module AR
      module DSL
        def self.included(base)
          base.extend(ClassMethods)
        end

        def cleanup(*objects)
          return if Lopata::Config.ops[:keep]
          objects.flatten.compact.each do |o|
            begin
              o.reload.destroy!
            rescue ActiveRecord::RecordNotFound
              # Already destroyed
            end
          end
        end

        def reload(*objects)
          objects.flatten.each(&:reload)
        end


        module ClassMethods
          def cleanup(*vars, &block)
            unless vars.empty?
              teardown do
                cleanup vars.map { |v| instance_variable_get "@#{v}" }
              end
            end
            teardown &block if block_given?
          end
        end
      end
    end
  end
end