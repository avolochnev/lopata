Feature: Using rspec-expectations

  Scenario: Passing scenario matching the expectation
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Passing scenario' do
        it 'works' do
          expect(1).to eq 1
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Failing scenario not matching the expectation
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Failing scenario' do
        it 'works' do
          expect(2 * 2).to eq 5
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 failed)"

