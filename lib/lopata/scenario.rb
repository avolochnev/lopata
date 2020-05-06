class Lopata::Scenario
  def self.define(title = nil, metadata = nil, &block)
    scenario = new
    scenario.title(title) if title
    scenario.metadata(metadata) if metadata
    scenario.instance_exec &block
    scenario.build_rspec
  end

  # Do noting. Exclude defined scenario from suite.
  def self.xdefine(*attrs)
  end

  def build_rspec
    option_combinations.each do |option_set|
      args = prepare_args(option_set)
      raise "scenario required a name in first argument" unless args.first.is_a? String
      steps = @steps
      spec = RSpec.describe(*args)
      spec.send :extend, RSpecInjections
      spec.nested_with_as(*args) do
        steps.each do |block|
          instance_exec &block
        end
        if Lopata::Config.after_scenario
          instance_exec &Lopata::Config.after_scenario
        end
      end
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

  %i{setup action it context teardown include_context include_examples}.each do |name|
    name_if = "%s_if" % name
    name_unless = "%s_unless" % name
    define_method name, ->(*args, &block) { add_step(name, *args, &block) }
    define_method name_if, ->(condition, *args, &block) { add_if_step(name, condition, *args, &block) }
    define_method name_unless, ->(condition, *args, &block) { add_unless_step(name, condition, *args, &block) }
  end

  def cleanup(*args, &block)
    add_step_as_is(:cleanup, *args, &block)
  end

  def add_step(method_name, *args, &block)
    @steps ||= []
    @steps << Proc.new do
      # will be called in context of rspec group
      flat_args = args.flatten
      flat_args = Lopata::Scenario.separate_args(flat_args) if method_name =~ /^(setup|action)/
      converted_args = Lopata::Scenario.convert_args(metadata, *flat_args)
      send method_name, *converted_args, &block
    end
  end

  def add_if_step(method_name, condition, *args, &block)
    @steps ||= []
    @steps << Proc.new do
      # will be called in context of rspec group
      if match_metadata?(condition)
        flat_args = args.flatten
        flat_args = Lopata::Scenario.separate_args(flat_args) if method_name =~ /^(setup|action)/
        converted_args = Lopata::Scenario.convert_args(metadata, *flat_args)
        send method_name, *converted_args, &block
      end
    end
  end

  def add_unless_step(method_name, condition, *args, &block)
    @steps ||= []
    @steps << Proc.new do
      # will be called in context of rspec group
      unless match_metadata?(condition)
        flat_args = args.flatten
        flat_args = Lopata::Scenario.separate_args(flat_args) if method_name =~ /^(setup|action)/
        converted_args = Lopata::Scenario.convert_args(metadata, *flat_args)
        send method_name, *converted_args, &block
      end
    end
  end

  def add_step_as_is(method_name, *args, &block)
    @steps ||= []
    @steps << Proc.new do
      # do not convert args - symbols mean name of instance variable
      send method_name, *args, &block
    end
  end

  def let_metadata(*keys)
    @steps ||= []
    @steps << Proc.new do
      m = metadata
      keys.each do |key|
        define_method key do
          m[key]
        end

        define_singleton_method key do
          m[key]
        end
      end
    end
  end

  def let_method(method_name, &block)
    @steps ||= []
    @steps << Proc.new do
      define_method method_name, &block
      define_singleton_method method_name, &block
    end
  end

  def steps(&block)
    @steps ||= []
    @steps << block
  end

  def steps_if(metadata_key, &block)
    @steps ||= []
    @steps << Proc.new do
      if match_metadata?(metadata_key)
        instance_exec &block
      end
    end
  end
  alias steps_for steps_if

  def steps_unless(metadata_key, &block)
    @steps ||= []
    @steps << Proc.new do
      unless match_metadata?(metadata_key)
        instance_exec &block
      end
    end
  end
  alias steps_for_not steps_unless

  def self.convert_args(metadata, *args)
    args.map do |arg|
      case arg
        # trait symbols as link to metadata.
        when Symbol then metadata[arg]
      else
        arg
      end
    end.flatten
  end

  def self.separate_args(args)
    args.map { |a| a.is_a?(String) && a =~ /,/ ? a.split(',').map(&:strip) : a }.flatten
  end

  def build_role_options
    return [] unless roles
    [Diagonal.new(:as, roles.map { |r| [nil, r] })]
  end

  def roles
    return false if @without_user
    @roles ||= [Lopata::Config.default_role].compact
  end

  def title(value)
    @title = value
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
    return source_combinations if rest_options.blank?
    combinations = []
    current_option = rest_options.shift
    source_combinations.each do |source_variants|
      current_option.level_variants.each do |v|
        combinations << (source_variants + OptionSet.new(v))
      end
    end
    combine(combinations, rest_options)
  end

  def prepare_args(option_set, *args)
    options_title, metadata = option_set.title, option_set.metadata
    if args[0].is_a? String
      args[0] = [@title, options_title, args[0]].reject(&:blank?).join(' ')
    else
      args.unshift([@title, options_title].reject(&:blank?).join(' '))
    end

    metadata.merge!(@common_metadata) if @common_metadata

    if args.last.is_a? Hash
      args.last.merge!(metadata)
    else
      args << metadata
    end
    args
  end

  # Набор вариантов, собранный для одного теста
  class OptionSet
    attr_reader :variants
    def initialize(*variants)
      @variants = {}
      variants.each { |v| self << v }
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

  # RSpec helpers for spec builing
  module RSpecInjections
    def match_metadata?(metadata_key)
      case metadata_key
      when Hash
        metadata_key.keys.all? { |k| metadata[k] == metadata_key[k] }
      when Array
        metadata_key.map { |key| metadata[key] }.none?(&:nil?)
      else
        metadata[metadata_key]
      end
    end
  end
end