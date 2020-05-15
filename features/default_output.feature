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

  Scenario: Display failed source code line
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Failed' do
        it 'fails' do
          expect(1).to eq 2
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "expect(1).to eq 2"

  Scenario: Display steps status on scenario failure
    Given a file named "shared_steps/scenario.rb" with:
      """ruby
      Lopata.shared_step 'empty data array' do
        setup { @data = [] }
        teardown { @data = nil }
      end

      Lopata.shared_step 'stop testing' do
        action { raise "Failed action skip all following actions except teardowns" }
      end
      """
    And a file named "scenario.rb" with:
      """ruby
      Lopata.define 'Mutistep scenario' do
        setup 'empty data array'
        action { @data << 1 }

        it 'works' do
          expect(@data).to eq []
        end

        action 'stop testing'

        it 'skipped' do
          expect(1).to eq 2
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain:
      """
        [+] Setup empty data array
        [+] Untitled action
        [!] works
      """
    And the output should contain:
      """
        [!] Action stop testing
      """
    And the output should contain:
      """
        [-] skipped
        [+] Teardown empty data array
      """
    And the output should contain "1 scenario (1 failed)"
