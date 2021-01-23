Feature: Roles

  Optional roles setup allows to generate scenarios to be run with different roles.

  Roles functionality must be initialized by requiring 'lopata/role'. It allows to declare roles and define set of
  roles to be used in the scenario.

  Roles definition can be done in configuration block by passing code => name hash to role_descriptions. Default role may be configured with default_role.

  Background:
    Given a file named "env.rb" with:
      """ruby
      require 'lopata/role'

      Lopata.configure do |c|
        c.role_descriptions = {
          user: 'simple user',
          admin: 'administrator',
          guest: 'guest',
        }
        c.default_role = :user
        c.before_scenario 'setup test user'
      end

      Lopata.shared_step 'setup test user' do
        setup do
          # do test user setup here
          if current_role
            @test_user = { username: current_role }
          else
            @test_user = nil
          end
        end
        teardown { @test_user = nil }
      end
      """

  Scenario: Run scenario with different roles
    Given a file named "scenario.rb" with:
      """ruby
      require_relative 'env'

      Lopata.define 'All roles run' do
        as :user, :admin, :guest

        it 'works' do
          expect(%i{ user admin guest }).to include(@test_user[:username])
        end
      end

      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "3 scenarios (3 passed)"


  Scenario: By default all scenarios run with default role
    Given a file named "scenario.rb" with:
      """ruby
      require_relative 'env'

      Lopata.define 'Default role run' do
        it 'works' do
          expect(@test_user[:username]).to eq :user
        end
      end

      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"


  Scenario: Awoid test user generation for certan scenarios
    Given a file named "scenario.rb" with:
      """ruby
      require_relative 'env'

      Lopata.define 'Run without user' do
        without_user

        it 'works' do
          expect(@test_user).to be_nil
        end
      end

      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "1 scenario (1 passed)"


  Scenario: Run scenario with some roles
    Given a file named "scenario.rb" with:
      """ruby
      require_relative 'env'

      Lopata.define 'First role run' do
        as_first :user, :admin, :guest

        it 'works' do
          expect(@test_user[:username]).to eq :user
        end
      end

      Lopata.define 'First roles taken for diagonals' do
        as_first :user, :admin, :guest
        diagonal :iteration, 'one' => :user, 'two' => :admin

        it 'works' do
          expect(@test_user[:username]).to eq iteration
        end
      end

      """
    When I run `bundle exec lopata scenario.rb`
    Then the output should contain "3 scenarios (3 passed)"

