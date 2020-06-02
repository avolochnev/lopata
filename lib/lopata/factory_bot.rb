require_relative 'active_record'

module Lopata
  # Helpers for FactoryBot usage in tests.
  #
  # Make helpers available in scenarios by
  #
  #     require 'lopata/factory_bot'
  #
  # Automatically adds ActiveRecord helpers.
  # @see Lopata::ActiveRecord
  #
  # Allows to create ActiveRecord object by FactoryBot definitions.
  # All the objects created by FactoryBot helpers will be destroyed automatically
  # at the end of scenario.
  # @see Lopata::ActiveRecord::Methods#cleanup
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
  #     require 'factory_bot'
  #     require 'lopata/facotory_bot'
  #
  #     class User < ActiveRecord::Base; end
  #
  #     FactoryBot.define do
  #       factory :user do
  #         username { 'testuser' }
  #       end
  #     end
  #
  #     Lopata.define 'User creation' do
  #       setup do
  #         @user = create(:user)
  #       end
  #       # No cleanup needed - @user will be destroyed automatically
  #       # cleanup :user
  #
  #       it 'works' do
  #         expect(@user).to_not be_nil
  #       end
  #     end
  #
  module FactoryBot
    # To be included in Lopata::Scenario
    module Methods
      # Wrapper for FactoryBot#create
      # Calls the FactoryBot#create with given paramters and returns it result.
      # Additionally store the created object for destroying at the end of scenario.
      # @see Lopata::ActiveRecord::Methods#cleanup
      def create(*params)
        cleanup_later ::FactoryBot.create(*params)
      end
    end

    # To be included in Lopata::ScenarioBuilder
    module DSL
    end
  end
end

Lopata::Scenario.include Lopata::FactoryBot::Methods
Lopata::ScenarioBuilder.include Lopata::FactoryBot::DSL

::FactoryBot.find_definitions
