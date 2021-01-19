Feature: Conditional actions, setup and validations

  Conditional actions action_if, action_unless, setup_if and setup_unless can be skipped depending on metadata values.

  Scenario: Positive conditions in action
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Conditional actions' do
        diagonal :add_data?,
          'run' => true,
          'skip' => false

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

  Scenario: Boolean values in conditional actions
    Given a file named "scenario.rb" with:
      """ruby
      [
        ['skip', false],
        ['run', true],
      ].each do |title, add_data|
        Lopata.define 'Conditional actions %s' % title do
          setup { @data = [] }
          action_if(add_data) { @data << 1 }

          it_if add_data, 'runned' do
            expect(add_data).to eq true
            expect(@data).to eq [1]
          end

          it_unless add_data, 'skipped' do
            expect(add_data).to eq false
            expect(@data).to eq []
          end
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"
