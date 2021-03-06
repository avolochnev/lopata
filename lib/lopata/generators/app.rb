module Lopata
  # @private
  module Generators
    # @private
    class App < Thor::Group
      include Thor::Actions
      argument :name

      def self.source_root
        File.join(File.dirname(__FILE__), 'templates')
      end

      def create_root_files
        template 'Lopatafile', "#{name}/Lopatafile"
        template 'Gemfile', "#{name}/Gemfile"
        template 'config/environments/qa.yml', "#{name}/config/environments/qa.yml"
        template 'config/initializers/capybara.rb', "#{name}/config/initializers/capybara.rb"
      end

      def init_dirs
        %w{models services pages}.each do |dir|
          empty_directory "#{name}/app/#{dir}"
        end

        %w{scenarios shared_steps config/initializers}.each do |dir|
          empty_directory "#{name}/#{dir}"
        end
      end

      def bundle
        Dir.chdir name do
          _bundle_command = Gem.bin_path('bundler', 'bundle')

          require 'bundler'
          Bundler.with_clean_env do
            output = `"#{Gem.ruby}" "#{_bundle_command}"`
            print output # unless options[:quiet]
          end
        end
      end
    end
  end
end