Feature: Metadata

  Scenario: Using metadata to define variable steps
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'empty data array' do
        setup { @data = [] }
      end

      Lopata.shared_step 'single element data array' do
        setup 'empty data array' do
          @data << 1
        end
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Setup steps defined via metadata' do
        diagonal :array_setup,
          'empty' => 'empty data array',
          'one element' => 'single element data array'

        setup :array_setup

        it 'works' do
          expect(@data.length).to be < 2
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Metadata available in steps as a method
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Metadata as a method' do
        diagonal :number,
          'one' => 1,
          'zero' => 0

        it 'passed' do
          expect(number).to be < 2
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Multi-level metadata in steps
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Multi-level metadata as a method' do
        diagonal :number,
          'one' => { source: 1, target: 1 },
          'two' => { source: 2, target: 4 }

        it 'passed' do
          expect(number_source * number_source).to eq number_target
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Using multi-level metadata to define variable steps
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'empty data array' do
        setup { @data = [] }
      end

      Lopata.shared_step 'single element data array' do
        setup 'empty data array' do
          @data << 1
        end
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Setup steps defined via metadata' do
        diagonal :array,
          'empty' => { setup: 'empty data array', expect: [] },
          'one element' => { setup: 'single element data array', expect: [1] }

        setup :array_setup

        it 'works' do
          expect(@data).to eq array_expect
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"
