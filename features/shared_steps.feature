Feature: Shared steps

  Scenario: Setup test data before validation
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'empty data array' do
        setup { @data = [] }
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Action scenario' do
        setup 'empty data array'
        action { @data << 1 }

        it 'works after initial change' do
          expect(@data).to eq [1]
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Shared steps may used other shared steps
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
      Lopata.define 'Initial shared setup' do
        setup 'single element data array'

        it 'may use other shared steps' do
          expect(@data).to eq [1]
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Shared steps may be included in single setup/action
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'empty data array' do
        setup { @data = [] }
      end

      Lopata.shared_step 'add data to array' do
        setup { @data << 1 }
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Multiple shared steps' do
        setup 'empty data array', 'add data to array'

        it 'may be combined' do
          expect(@data).to eq [1]
        end
      end

      Lopata.define 'Comma-separated shared steps' do
        setup 'empty data array, add data to array'

        it 'may be used' do
          expect(@data).to eq [1]
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Comma is not allowed in shared step name
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'comma, in name' do
        setup {}
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Never runned scenario' do
        setup 'comma, in name'

        it 'not runned' do
          expect(1).to eq 1
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "Comma is not allowed in shared step name"
