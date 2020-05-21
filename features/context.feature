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
