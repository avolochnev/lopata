# @private
module Lopata::Loader
  extend self

  # Loads scenarios for running in current session
  #
  # @param args [Array<String>] files to be load.
  #   All files from default location to be loaded if empty.
  def load_scenarios(*args)
    if args.empty?
      load_all_scenarios
    else
      args.each do |file|
        load File.expand_path(file)
      end
    end
  end

  # Loads all scenarios from predefined paths
  def load_all_scenarios
    Dir["scenarios/**/*.rb"].each { |f| load File.expand_path(f) }
  end

  # Loads all shared steps from predefined paths
  def load_shared_steps
    Dir["shared_steps/**/*rb"].each { |f| load File.expand_path(f) }
  end
end