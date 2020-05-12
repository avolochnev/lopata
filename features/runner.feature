Feature: Run tests using lopata.

  Scenario: Run without tests
    When I run `bundle exec lopata`
    Then the output should contain "0 scenarios"

  Scenario: Run test from file via argument
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Empty scenario' do
        it('works') {}
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario"

  Scenario: Run tests from predefined path when no arguments passed
    Given a file named "scenarios/scenario.rb" with:
      """ruby
      Lopata.define 'Empty scenario' do
        it('works') {}
      end
      """
    When I run `bundle exec lopata`
    Then the output should contain "1 scenario"
