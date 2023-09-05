Feature: Conditions calculated during script running.

  Conditional actions and validations are defined by metadata and calculated on script building.
  Passing lambda as condition it is posible turn off some validations of action durint test running

  Scenario: Dynamic condition
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Conditional actions' do
        diagonal :add_data?,
          'added' => true,
          'skipped' => false

        setup { @data = [] }
        action_if(:add_data?) { @data << 1 }

        it_if -> { @data.length > 0 }, 'added' do
          expect(@data).to eq [1]
        end

        it_unless -> { @data.length > 0 }, 'skipped' do
          expect(@data).to eq []
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Dynamic condition in context
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Conditional context' do
        diagonal :add_data?,
          'added' => true,
          'skipped' => false

        setup { @data = [] }
        action_if(:add_data?) { @data << 1 }
        let(:last_item) { @data.last }

        context_if -> { last_item }, 'when added' do
          it 'not empty' do
            expect(last_item).to_not be_nil
          end

          it 'equial 2' do
            expect(last_item).to eq 2 # failed
          end
        end

        context_unless -> { last_item }, 'skipped' do
          let!(:two) { 2 }
          it 'empty' do
            expect(last_item).to be_nil
          end

          context_unless -> {last_item}, 'nested' do
            it 'no value' do
              expect(last_item).to_not eq two
            end
          end

        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (1 failed, 1 passed)"

