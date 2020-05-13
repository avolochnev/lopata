Feature: Conditional actions, setup and validations

  Conditional actions action_if, action_unless, setup_if and setup_unless can be skipped depending on metadata values.

  Scenario: Positive conditions in action
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Conditional actions' do
        diagonal :add_data?,
          'skip' => true,
          'run' => false

        setup { @data = [] }
        action_if(:add_data?) { @data << 1 }

        it_if :add_data?, 'runned' do
          expect(@data).to eq [1]
        end

        it_unless :add_data?, 'skipped' do
          expect(@data).to eq []
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"
