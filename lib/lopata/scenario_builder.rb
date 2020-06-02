# Context for scenario creation.
class Lopata::ScenarioBuilder
  # @private
  attr_reader :title, :common_metadata, :options, :diagonals
  # @private
  attr_accessor :shared_step, :group

  # Defines one or more scenarios.
  #
  # @example
  #     Lopata.define 'scenario' do
  #       setup 'test user'
  #       action 'login'
  #       verify 'home page displayed'
  #     end
  #
  # Given block will be calculated in context of the ScenarioBuilder
  #
  # @param title [String] scenario unique title
  # @param metadata [Hash] metadata to be used within the scenario
  # @param &block [Proc] the scenario definition
  # @see Lopata.define
  def self.define(title, metadata = {}, &block)
    builder = new(title, metadata)
    builder.instance_exec &block
    builder.build
  end

  # @private
  def initialize(title, metadata = {})
    @title, @common_metadata = title, metadata
    @diagonals = []
    @options = []
  end

  # @private
  def build
    filters = Lopata.configuration.filters
    option_combinations.each do |option_set|
      metadata = common_metadata.merge(option_set.metadata)
      scenario = Lopata::Scenario::Execution.new(title, option_set.title, metadata)

      unless filters.empty?
        next unless filters.all? { |f| f[scenario] }
      end

      steps_with_hooks.each do |step|
        next if step.condition && !step.condition.match?(scenario)
        step.execution_steps(scenario).each { |s| scenario.steps << s }
      end

      world.scenarios << scenario
    end
  end

  # Define additional metadata for the scenario
  #
  # @example
  #     Lopata.define 'scenario' do
  #       metadata key: 'value'
  #       it 'metadata available' do
  #         expect(metadata[:key]).to eq 'value'
  #       end
  #     end
  def metadata(hash)
    raise 'metadata expected to be a Hash' unless hash.is_a?(Hash)
    @common_metadata ||= {}
    @common_metadata.merge! hash
  end

  # Skip scenario for given variants combination
  #
  # @example
  #     Lopata.define 'multiple options' do
  #       option :one, 'one' => 1, 'two' => 2
  #       option :two, 'two' => 2, 'three' => 3
  #       skip_when { |opt| opt.metadata[:one] == opt.metadata[:two] }
  #       it 'not equal' do
  #         expect(one).to_not eq two
  #       end
  #     end
  #
  def skip_when(&block)
    @skip_when = block
  end

  # private
  def skip?(option_set)
    @skip_when && @skip_when.call(option_set)
  end

  # @!group Defining Steps

  # @private
  # @macro [attach] define_step_method
  #   @!scope class
  #   @method $1
  #   @overload $1(*args, **metadata, &block)
  #     @param args [Array<String, Symbol, Proc>] the step parameters.
  #     @param metadata [Hash] the step additional metadata
  #     @param block [Block] The implementation of the step.
  def self.define_step_method(name)
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

  # Define setup step.
  # @example
  #   setup do
  #   end
  #
  #   # setup from named shared step
  #   setup 'create user'
  #
  #   # setup with both shared step and code block
  #   setup 'create user' do
  #     @user.update(admin: true)
  #   end
  #
  # Setup step used for set test data.
  define_step_method :setup

  # Define action step.
  # @example
  #   action do
  #   end
  #
  #   # action from named shared step
  #   action 'login'
  #
  #   # setup with both shared step and code block
  #   action 'login', 'go dashboard' do
  #     @user.update(admin: true)
  #   end
  #
  # Action step is used for emulate user or external system action
  define_step_method :action

  # Define teardown step.
  # @example
  #   setup { @user = User.create! }
  #   teardown { @user.destroy }
  # Teardown step will be called at the end of scenario running.
  # But it suggested to be decared right after setup or action step which require teardown.
  define_step_method :teardown

  # Define verify steps.
  # @example
  #   verify 'home page displayed' # call shared step.
  # Usually for validation shared steps inclusion
  define_step_method :verify

  # Define group of steps.
  # The metadata for the group may be overriden
  # @example
  #   context 'the task', task: :created do
  #     verify 'task setup'
  #     it 'created' do
  #       expect(metadata[:task]).to eq :created
  #     end
  #   end
  # Teardown steps within group will be called at the end of the group, not scenario
  # @overload context(title, **metadata, &block)
  #   @param title [String] context title
  #   @param metadata [Hash] the step additional metadata
  #   @param block [Block] The implementation of the step.
  define_step_method :context

  # Define single validation step.
  # @example
  #   it 'works' do
  #     expect(1).to eq 1
  #   end
  # @overload context(title, **metadata, &block)
  #   @param title [String] validation title
  #   @param block [Block] The implementation of the step.
  define_step_method :it

  # Define runtime method for the scenario.
  #
  # @example
  #   let(:square) { |num| num * num }
  #   it 'calculated' do
  #     expect(square(4)).to eq 16
  #   end
  def let(method_name, &block)
    steps << Lopata::Step.new(:let) do
      execution.let(method_name, &block)
    end
  end

  # @!endgroup

  # @private
  def add_step(method_name, *args, condition: nil, metadata: {}, &block)
    step_class =
      case method_name
      when /^(setup|action|teardown|verify)/ then Lopata::ActionStep
      when /^(context)/ then Lopata::GroupStep
      else Lopata::Step
      end
    step = step_class.new(method_name, *args, condition: condition, shared_step: shared_step, &block)
    step.metadata = metadata
    steps << step
  end

  # @private
  def steps
    @steps ||= []
  end

  # @private
  def steps_with_hooks
    s = []
    unless Lopata.configuration.before_scenario_steps.empty?
      s << Lopata::ActionStep.new(:setup, *Lopata.configuration.before_scenario_steps)
    end

    s += steps

    unless Lopata.configuration.after_scenario_steps.empty?
      s << Lopata::ActionStep.new(:teardown, *Lopata.configuration.after_scenario_steps)
    end

    s
  end

  def option(metadata_key, variants)
    @options << Option.new(metadata_key, variants)
  end

  def diagonal(metadata_key, variants)
    @diagonals << Diagonal.new(metadata_key, variants)
  end

  # @private
  def option_combinations
    combinations = combine([OptionSet.new], options + diagonals)
    while !diagonals.all?(&:complete?)
      combinations << OptionSet.new(*(options + diagonals).map(&:next_variant))
    end
    combinations.reject { |option_set| skip?(option_set) }
  end

  # @private
  def combine(source_combinations, rest_options)
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

  # @private
  def world
    Lopata.world
  end

  # @private
  # Set of options for scenario
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

  # @private
  class Variant
    attr_reader :key, :title, :value, :option

    def initialize(option, key, title, value)
      @option, @key, @title, @value = option, key, title, check_lambda_arity(value)
    end

    def metadata(option_set)
      data = { key => value }
      if value.is_a? Hash
        value.each do |k, v|
          sub_key = "%s_%s" % [key, k]
          data[sub_key.to_sym] = v
        end
      end

      option.available_metadata_keys.each do |key|
        data[key] = nil unless data.has_key?(key)
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

  # @private
  class CalculatedValue
    def initialize(&block)
      @proc = block
    end

    def calculate(option_set)
      @proc.call(option_set)
    end
  end

  # @private
  class Option
    attr_reader :variants, :key
    def initialize(key, variants)
      @key = key
      @variants =
        if variants.is_a? Hash
          variants.map { |title, value| Variant.new(self, key, title, value) }
        else
          # Array of arrays of two elements
          variants.map { |v| Variant.new(self, key, *v) }
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

    def available_metadata_keys
      @available_metadata_keys ||= variants
        .map(&:value).select { |v| v.is_a?(Hash) }.flat_map(&:keys).map { |k| "#{key}_#{k}".to_sym  }.uniq
    end
  end

  # @private
  class Diagonal < Option
    def level_variants
      [next_variant]
    end

    def complete?
      @complete
    end
  end
end
