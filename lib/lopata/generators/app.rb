module Lopata
  module Generators
    class App < Thor::Group
      include Thor::Actions
      argument :name

      def self.source_root
        File.join(File.dirname(__FILE__), 'templates')
      end

      def create_root_files
        template 'Lopatafile', "#{name}/Lopatafile"
        template 'Gemfile', "#{name}/Gemfile"
        template '.rspec', "#{name}/.rspec"
        template 'config/environments/qa.yml', "#{name}/config/environments/qa.yml"
        template 'config/initializers/capybara.rb', "#{name}/config/initializers/capybara.rb"
      end

      def init_dirs
        %w{models services pages}.each do |dir|
          empty_directory "#{name}/app/#{dir}"
        end

        %w{spec config/initializers}.each do |dir|
          empty_directory "#{name}/#{dir}"
        end
      end
    end
  end
end