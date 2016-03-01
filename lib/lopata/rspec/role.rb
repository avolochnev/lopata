module Lopata::RSpec::Role
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Filter names
  def self.filter_roles *names
    allowed = Lopata::Config.only_roles
    selected = names.flatten.select { |n| allowed.blank? || allowed.member?(n) }
    # ENV['quick'] ? [selected.first] : selected
    selected
  end

  # http://jorgemanrubia.net/2010/01/16/using-macros-to-create-custom-example-groups-in-rspec/
  module ClassMethods
    def as *names, &block
      return if current_role && !Lopata::RSpec::Role.filter_roles(*names).include?(current_role)
      if current_role
        self.class_eval(&block)
      else
        Lopata::RSpec::Role.filter_roles(*names).each do |name|
          example_group_class = describe role_description(name), :current_role => name do
            instance_exec &Lopata::Config.after_as if Lopata::Config.after_as
            define_method :current_role do
              name
            end
          end
          example_group_class.class_eval(&block)
        end
      end
    end

    def except(*names, &block)
      raise "'expecpt' block must be neseted for 'as' block" unless current_role
      return if names.include? current_role
      self.class_eval(&block)
    end

    def current_role
      metadata[:current_role]
    end

    # To be redefined in impelemntations so RSpec descriptions to be more verbal
    def role_description(name)
      Lopata::Config.role_descriptions[name] || name
    end

    def scenario(*args, &block)
      raise "scenario required a name in first argument" unless args.first.is_a? String
      example_group_class = describe(*args)
      example_group_class.nested_with_as(*args, &block)
    end

    def nested_with_as(*args, &block)
      if (args.last.is_a?(Hash) && args.last[:as])
        roles = args.last[:as]
        roles = [roles] unless roles.is_a?(Array)
        class_eval { as(*roles, &block) }
      else
        class_eval(&block)
      end
    end
  end
end

module Lopata
  # Adds the #scenario method to the top-level namespace.
  def self.scenario(*args, &block)
    raise "scenario required a name in first argument" unless args.first.is_a? String
    example_group_class = RSpec.describe(*args)
    example_group_class.nested_with_as(*args, &block)
    # example_group_class.register
  end
end

