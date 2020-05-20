Feature: Pending steps

  Steps may be marked as pending. Scenario it won't be failed when pending step fails.

  Like RSpec, step will be failed if it it pending but not raise an error, so fixed scenarios can be detected.

  Scenario: Pending step don't fail scenario.
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Scenario with pending step' do
        it 'fails' do
          pending 'Not implemented yet'
          expect(1).to eq 2
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"

  Scenario: Pending step fails when not raise error.
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Scenario with pending step' do
        it 'pass' do
          pending 'Not implemented yet'
          expect(1).to eq 1
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 failed)"
    And the output should contain:
      """
        [!] pass
      """
    And the output should contain "Expected step to fail since it is pending, but it passed."
