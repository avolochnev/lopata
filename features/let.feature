Feature: Define methods in scenarios

  Scenario: Use #let to define methods
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Method definition with #let' do
        diagonal :number,
          'one' => 1,
          'two' => 2
        let(:square) { number * number }

        it 'passed' do
          expect(number * number).to eq square
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Methods are available in setup running
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Method definition with #let' do
        let(:square) { number * number }
        diagonal :number,
          'one' => 1,
          'two' => 2
        setup do
          @expect = square
        end

        it 'passed' do
          expect(number * number).to eq @expect
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Methods may be defined in shared step
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'empty data array' do
        let(:default_data) { [] }
        setup { @data = default_data }
      end
      """
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Method defined in shared step' do
        setup 'empty data array'

        it 'is available in tests' do
          expect(@data).to eq default_data
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Memorized methods with let!
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'memorized method' do
        let!(:default_data) { Time.now }
        setup { @data = default_data }
      end
      """
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Memorized method defined in shared step' do
        setup 'memorized method'

        it 'is memorized' do
          expect(@data).to eq default_data
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

