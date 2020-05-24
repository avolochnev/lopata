Feature: Context

  Scenario: Context override metadata
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.shared_step 'got overriden metadata' do
        it 'even in shared step' do
          expect(metadata[:number]).to eq 4
        end
      end
      Lopata.define 'Metadata within context' do
        diagonal :number,
          'one' => 1,
          'zero' => 0

        it 'passed' do
          expect(number).to be < 2
        end

        context 'may be', number: 4 do
          it 'overriden' do
            expect(number).to eq 4
          end

          verify 'got overriden metadata'
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "2 scenarios (2 passed)"

  Scenario: Context output in steps
    Given a file named "scenario.rb" with:
      """ruby
      Lopata.shared_step 'in shared step' do
        it 'shared step' do
          expect(number).to eq 1
        end
      end
      Lopata.define 'Metadata within context' do
        let(:number) { 1 }

        it 'passed' do
          expect(number).to be < 2
        end

        context 'in group', number: 4 do
          it 'failed' do
            expect(number).to be < 1
          end

          verify 'in shared step'
        end
      end
      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain:
      """
        [+] passed
        [!] in group: failed
      """
    And the output should contain:
      """
        [+] in group: shared step
      """
