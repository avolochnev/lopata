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

  Scenario: Run test from file via argument by mask
    Given a file named "scenarios1/scenario1.rb" with:
      """ruby
      Lopata.define 'Empty scenario' do
        it('works') {}
      end
      """
    Given a file named "scenarios1/with_subfolder/scenario2.rb" with:
      """ruby
      Lopata.define 'Empty scenario' do
        it('works') {}
      end
      """
    Given a file named "scenarios2/scenario3.rb" with:
      """ruby
      Lopata.define 'Empty scenario' do
        it('works') {}
      end
      """
    Given a file named "scenarios3/scenario.rb" with:
      """ruby
      Lopata.define 'Failing scenario' do
        it('fails') { expect(1).to eq 2 }
      end
      """
    When I run `bundle exec lopata scenarios1/**/*.rb scenarios2/**/*.rb`
    Then the output should contain "3 scenarios (3 passed)"

