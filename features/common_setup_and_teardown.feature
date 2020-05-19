Feature: Common setup and teardown

  Common setup and teardown steps to be runned before and after each scenario.

  Background:
    Given a file named "env.rb" with:
      """ruby
      Lopata.configure do |c|
        c.before_scenario 'array'
      end

      Lopata.shared_step 'array' do
        setup { @array = [] }
        teardown { @array = nil }
      end
      """

  Scenario: Using common setup and teardown
    Given a file named "scenario.rb" with:
      """ruby
      require_relative 'env'

      Lopata.define 'Common setup' do
        action { @array << 1 }

        it 'used' do
          expect(@array).to eq [1]
        end
      end

      Lopata.define 'Common setup in another scenario' do
        it 'is reset' do
          expect(@array).to eq []
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

