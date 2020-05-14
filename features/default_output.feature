Feature: Output results

  Scenario: Output test names
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
    Then the output should contain:
      """
      Multi-level metadata as a method one PASSED
      Multi-level metadata as a method two PASSED
      """

  Scenario: Backtrace filtering
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Failed' do
        it 'fails' do
          expect(1).to eq 2
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "scenario.rb:3"
    And the output should not contain "rspec"
    And the output should not contain "thor"
    And the output should not contain "gems"


