module Lopata
  # Helpers for ActiveRecord usage in tests.
  #
  # Make helpers available in scenarios by
  #
  #     require 'lopata/active_record'
  #
  # @example
  #
  #     # Configure db connection at config/environments/qa.yml like rails:
  #     # db:
  #     #   adapter: postgresql
  #     #   host: your.database.host
  #     #   username: username
  #     #   password: password
  #     #   database: database
  #     require 'active_record'
  #     require 'lopata/active_record'
  #
  #     class User < ActiveRecord::Base; end
  #
  #     Lopata.define 'User creation' do
  #       setup do
  #         @user = User.create!(username: 'testuser')
  #       end
  #       # Remove user from database after scenario
  #       cleanup :user
  #
  #       it 'works' do
  #         expect(@user).to_not be_nil
  #       end
  #     end
  #
  module ActiveRecord
    # To be included in Lopata::Scenario. The methods may be used in runtime.
    module Methods
      # Destroy ActiveRecord objects.
      #
      # Does nothing if 'keep' mode is enabled:
      #
      #     Lopata.configure do |c|
      #       c.keep = true
      #     end
      #
      # @param objects [Array<ActiveRecord::Base, Array<ActiveRecord::Base>, nil>] to be destroyed
      # @see Lopata::Configuration#keep
      def cleanup(*objects)
        return if Lopata.configuration.keep
        objects.flatten.compact.each do |o|
          begin
            o.reload.destroy!
          rescue ::ActiveRecord::RecordNotFound
            # Already destroyed - skip
          rescue ::ActiveRecord::InvalidForeignKey
            # Possible async job created new relationships (e.g. history records). Try again once.
            o.reload.destroy!
          end
        end
      end

      # Reload ActiveRecord objects
      #
      # @example
      #
      #     # use in steps
      #     reload @a, @b
      #     # instead of
      #     @a.reload; @b.reload
      #
      # @param objects [Array<ActiveRecord::Base, Array<ActiveRecord::Base>, nil>] to be reloaded
      def reload(*objects)
        objects.flatten.compact.each(&:reload)
      end

      # Marks object to be destroyed at the end of scenario
      #
      # @param object [ActiveRecord::Base] the object to be destoryed at the end of scenario
      # @return the given object, so chains can be build
      def cleanup_later(object)
        return nil unless object
        @created_objects ||= []
        @created_objects << object
        object
      end

      # Find ActiveRecord object of given class by params.
      # Marks the returned object to be destroyed at the end of scenario.
      #
      # @example
      #     action do
      #       # UI actions creating the user
      #       @user = find_created(User, username: 'testuser')
      #     end
      #     it 'created' do
      #       expect(@user).to_not be_nil
      #     end
      #     # No cleanup needed
      #     # cleanup :user
      #
      # @param cls [Class] active record model class
      # @param params [Hash] options for record finding
      # @return [ActiveRecord::Base, nil] the object or nil if not found
      # @see #cleanup_later called on the hood
      def find_created(cls, params)
        cleanup_later cls.where(params).take
      end
    end

    # To be included in Lopata::ScenarioBuilder. The methods may be used in build time.
    module DSL
      # Mark instance variables to call #destroy at teardown phase of scenario or context running.
      #
      # Does nothing if 'keep' mode is enabled.
      #
      # @param vars [Array<Symbol, String>] instance variable names to be destroyed on teardown phase.
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

Lopata.configure do |c|
  c.after_scenario { cleanup @created_objects }
end

params = Lopata.environment['db']
ActiveRecord::Base.establish_connection(params) if params

Lopata::Scenario.include Lopata::ActiveRecord::Methods
Lopata::ScenarioBuilder.include Lopata::ActiveRecord::DSL