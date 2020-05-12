Feature: Diagonal test generation

  Very othen one test must be runned with different test data. Diagonals allow to generate multple similar tests
  with different set of test data.

  Scenario: Multiple tests from one scenario
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Passing scenario' do
        diagonal :number, 'one' => 1, 'two' => 2, 'three' => 3

        it 'must be odd' do
          expect(metadata[:number]).to be_odd
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "3 scenarios (2 passed, 1 failed)"

