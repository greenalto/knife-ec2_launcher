require 'yaml'

class Chef
  class Knife
    class YAMLProfiles
      attr_reader :config_file

      def initialize(config_file)
        raise "No config file found at #{config_file}" unless File.exist? config_file
        @config_file = config_file
      end

      # list of profile names
      def all
        @available_profiles ||= yaml_config['profiles'].map(&:first)
      end

      def [](profile)
        @profile_from_config ||= yaml_config['profiles'][profile]
      end

      private

      def yaml_config
        @yaml_config ||= YAML.load_file(@config_file)
      end
    end
  end
end
