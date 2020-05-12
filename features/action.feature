Feature: Action

  Action is a user or external system activity affects the system under test.

  Actions can be called before and after validation steps, so intermediate state can be validated by the test.

  Scenario: Setup test data before validation
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Action scenario' do
        setup { @data = [] }
        action { @data << 1 }

        it 'works after initial change' do
          expect(@data).to eq [1]
        end

        action { @data << 2 }

        it 'works after second change' do
          expect(@data).to eq [1, 2]
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"
