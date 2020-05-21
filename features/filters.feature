Feature: Filters

  Filters allow to select scenarios to be runned.

  Scenario: Fitler by scenario title
    Given a file named "scenarios/scenario.rb" with:
      """ruby
      Lopata.define 'Scenario one' do
        it('works') {}
      end

      Lopata.define 'Scenario two' do
        it('works') {}
      end
      """
    When I run `bundle exec lopata -t "Scenario one"`
    Then the output should contain "1 scenario (1 passed)"
    And the output should contain:
      """
      Scenario one PASSED
      """

  Scenario: Fitler by scenario title when file given
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Scenario one' do
        it('works') {}
      end

      Lopata.define 'Scenario two' do
        it('works') {}
      end
      """
    When I run `bundle exec lopata scenario.rb -t "Scenario one"`
    Then the output should contain "1 scenario (1 passed)"
    And the output should contain:
      """
      Scenario one PASSED
      """
