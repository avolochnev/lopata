class Lopata::ScenarioBuilder
  attr_reader :title, :common_metadata
  attr_accessor :shared_step, :group

  def self.define(title, metadata = {}, &block)
    builder = new(title, metadata)
    builder.instance_exec &block
    builder.build
  end

  def initialize(title, metadata = {})
    @title, @common_metadata = title, metadata
  end

  def build
    option_combinations.each do |option_set|
      metadata = common_metadata.merge(option_set.metadata)
      scenario = Lopata::Scenario.new(title, option_set.title, metadata)

      steps_with_hooks.each do |step|
        next if step.condition && !step.condition.match?(scenario)
        step.pre_steps(scenario).each { |s| scenario.execution.steps << s }
        scenario.execution.steps << Lopata::StepExecution.new(step, &step.block) if step.block
      end

      world.scenarios << scenario
    end
  end

  def as(*args, &block)
    @roles = args.flatten
    @roles << CalculatedValue.new(&block) if block_given?
    @role_options = nil
  end

  def role_options
    @role_options ||= build_role_options
  end

  def metadata(hash)
    raise 'metadata expected to be a Hash' unless hash.is_a?(Hash)
    @common_metadata ||= {}
    @common_metadata.merge! hash
  end

  def without_user
    @without_user = true
  end

  def skip_when(&block)
    @skip_when = block
  end

  def skip?(option_set)
    @skip_when && @skip_when.call(option_set)
  end

  %i{ setup action it teardown verify context }.each do |name|
    name_if = "%s_if" % name
    name_unless = "%s_unless" % name
    define_method name, ->(*args, **metadata, &block) { add_step(name, *args, metadata: metadata, &block) }
    define_method name_if, ->(condition, *args, **metadata, &block) {
      add_step(name, *args, metadata: metadata, condition: Lopata::Condition.new(condition), &block)
    }
    define_method name_unless, ->(condition, *args, **metadata, &block) {
      add_step(name, *args, condition: Lopata::Condition.new(condition, positive: false), metadata: metadata, &block)
    }
  end

  def add_step(method_name, *args, condition: nil, metadata: {}, &block)
    step_class =
      case method_name
      when /^(setup|action|teardown|verify)/ then Lopata::ActionStep
      when /^(context)/ then Lopata::GroupStep
      else Lopata::Step
      end
    step = step_class.new(method_name, *args, condition: condition, shared_step: shared_step, group: group, &block)
    step.metadata = metadata
    steps << step
  end

  def steps
    @steps ||= []
  end

  def steps_with_hooks
    s = []
    unless Lopata::Config.before_scenario_steps.empty?
      s << Lopata::ActionStep.new(:setup, *Lopata::Config.before_scenario_steps)
    end

    s += steps

    unless Lopata::Config.after_scenario_steps.empty?
      s << Lopata::ActionStep.new(:teardown, *Lopata::Config.after_scenario_steps)
    end

    s
  end

  def cleanup(*args, &block)
    add_step_as_is(:cleanup, *args, &block)
  end

  def add_step_as_is(method_name, *args, &block)
    steps << Lopata::Step.new(method_name, *args) do
      # do not convert args - symbols mean name of instance variable
      # run_step method_name, *args, &block
      instance_exec(&block) if block
    end
  end

  def let(method_name, &block)
    steps << Lopata::Step.new(nil) do
      define_singleton_method method_name, &block
    end
  end

  def build_role_options
    return [] unless roles
    [Diagonal.new(:as, roles.map { |r| [nil, r] })]
  end

  def roles
    return false if @without_user
    @roles ||= [Lopata::Config.default_role].compact
  end

  def option(metadata_key, variants)
    options << Option.new(metadata_key, variants)
  end

  def diagonal(metadata_key, variants)
    diagonals << Diagonal.new(metadata_key, variants)
  end

  def options
    @options ||= []
  end

  def diagonals
    @diagonals ||= []
  end

  def option_combinations
    combinations = combine([OptionSet.new], options + diagonals + role_options)
    while !(diagonals + role_options).all?(&:complete?)
      combinations << OptionSet.new(*(options + diagonals + role_options).map(&:next_variant))
    end
    combinations.reject { |option_set| skip?(option_set) }
  end

  def combine(source_combinations, rest_options)
    # raise 'source_combinations cannot be empty' if source_combinations.blank?
    return source_combinations if rest_options.empty?
    combinations = []
    current_option = rest_options.shift
    source_combinations.each do |source_variants|
      current_option.level_variants.each do |v|
        combinations << (source_variants + OptionSet.new(v))
      end
    end
    combine(combinations, rest_options)
  end

  def world
    @world ||= Lopata::Config.world
  end

  # Набор вариантов, собранный для одного теста
  class OptionSet
    attr_reader :variants
    def initialize(*variants)
      @variants = {}
      variants.compact.each { |v| self << v }
    end

    def +(other_set)
      self.class.new(*@variants.values).tap do |sum|
        other_set.each { |v| sum << v }
      end
    end

    def <<(variant)
      @variants[variant.key] = variant
    end

    def [](key)
      @variants[key]
    end

    def each(&block)
      @variants.values.each(&block)
    end

    def title
      @variants.values.map(&:title).compact.join(' ')
    end

    def metadata
      @variants.values.inject({}) do |metadata, variant|
        metadata.merge(variant.metadata(self))
      end
    end
  end

  class Variant
    attr_reader :key, :title, :value

    def initialize(key, title, value)
      @key, @title, @value = key, title, check_lambda_arity(value)
    end

    def metadata(option_set)
      data = { key => value }
      if value.is_a? Hash
        value.each do |k, v|
          sub_key = "%s_%s" % [key, k]
          data[sub_key.to_sym] = v
        end
      end

      data.each do |key, v|
        data[key] = v.calculate(option_set) if v.is_a? CalculatedValue
      end
      data
    end

    def self.join(variants)
      title, metadata = nil, {}
      variants.each do |v|
        title = [title, v.title].compact.join(' ')
        metadata.merge!(v.metadata)
      end
      [title, metadata]
    end

    private

      # Лямдда будет передаваться как блок в instance_eval, которому плохеет, если пришло что-то с нулевой
      # arity. Поэтому для лямбд с нулевой arity делаем arity == 1
      def check_lambda_arity(v)
        if v.is_a?(Proc) && v.arity == 0
          ->(_) { instance_exec(&v) }
        else
          v
        end
      end
  end

  class CalculatedValue
    def initialize(&block)
      @proc = block
    end

    def calculate(option_set)
      @proc.call(option_set)
    end
  end

  class Option
    attr_reader :variants
    def initialize(key, variants)
      @variants =
        if variants.is_a? Hash
          variants.map { |title, value| Variant.new(key, title, value) }
        else
          # Array of arrays of two elements
          variants.map { |v| Variant.new(key, *v) }
        end
    end

    # Variants to apply at one level
    def level_variants
      variants
    end

    def next_variant
      @current ||= 0
      selected_variant = variants[@current]
      @current += 1
      if @current >= variants.length
        @current = 0
        @complete = true # all variants have been selected
      end
      selected_variant
    end
  end

  class Diagonal < Option
    def level_variants
      [next_variant]
    end

    def complete?
      @complete
    end
  end
end
