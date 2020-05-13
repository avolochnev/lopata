Feature: Setup and teardown

  Setup and teardown are steps for setup test data before scenario
  and cleanup it after.

  Teardown blocks are called at the end of scenario after all the validation
  so cleanup can be declared right after the setup block.

  Scenario: Setup test data before validation
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Setup scenario' do
        setup do
          @one = 1
        end

        it 'works' do
          expect(@one).to eq 1
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Teardown test data after run
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Setup scenario' do
        setup { @one = 1 }
        teardown { remove_instance_variable(:@one) }

        it 'works' do
          expect(@one).to eq 1
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Teardown order with shared steps
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'one' do
        setup { @one = 1 }
        teardown { remove_instance_variable(:@one) }
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Teardown in shared steps' do
        setup 'one'

        it 'works' do
          expect(@one).to eq 1
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

