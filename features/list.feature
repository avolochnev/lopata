Feature: List

  List name of scenarios in current scope. Allow to find name of complex scenarios and then filter by them.

  Scenario: List scenarios with filter by title
    Given a file named "scenarios/scenario.rb" with:
      """ruby
      Lopata.define 'Scenario one' do
        it('works') {}
      end

      Lopata.define 'Scenario two' do
        it('works') {}
      end
      """
    When I run `bundle exec lopata -t "Scenario one" -l`
    Then the stdout should contain exactly:
    """
    Scenario one
    """

  Scenario: List all scenarios
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Scenario one' do
        it('works') {}
      end

      Lopata.define 'Scenario two' do
        it('works') {}
      end
      """
    When I run `bundle exec lopata scenario.rb -l`
    Then the stdout should contain exactly:
    """
    Scenario one
    Scenario two
    """
