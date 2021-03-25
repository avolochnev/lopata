# @private
module Lopata::Loader
  extend self

  # Loads scenarios for running in current session
  #
  # @param args [Array<String>] files to be load.
  #   Mask (e. g. 'scenarios/**/*.rb') is can be passed as well.
  #   All files from default location to be loaded if empty.
  def load_scenarios(*args)
    if args.empty?
      load_all_scenarios
    else
      args.each(&method(:load_by_mask))
    end
  end

  # Loads all scenarios from predefined paths
  def load_all_scenarios
    load_by_mask "scenarios/**/*.rb"
  end

  # Loads all shared steps from predefined paths
  def load_shared_steps
    load_by_mask "shared_steps/**/*rb"
  end

  # @private
  def load_by_mask(mask)
    Dir[mask].each { |f| load File.expand_path(f) }
  end
end