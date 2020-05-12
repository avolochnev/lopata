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

