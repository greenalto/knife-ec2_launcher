# This plugin needs .chef/knife.rb populated with knife[:aws_access_key_id]
# and knife[:aws_secret_access_key] and a config/ec2.yml file

require 'chef/knife'
require 'chef/knife/ec2_base'
require 'chef/knife/ec2_server_create'

class Chef
  class Knife
    class Ec2ServerFromProfile < Knife
      include Knife::Ec2Base

      YAML_CONFIG_PATH = File.join(Dir.pwd, 'config/ec2.yml')

      deps do
        require 'yaml'
        require 'fog'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 server from profile NODE_NAME --profile=PROFILE (options)"

      # Inherit options from knife-ec2 plugin
      @options = Ec2ServerCreate.options.dup

      option :profile,
             :long        => '--profile PROFILE',
             :required    => true,
             :description => "Profile to load from the config file"

      # Set the config from the profile
      def initialize(argv=[], yaml_config_path=YAML_CONFIG_PATH)
        super(argv) # Pass argv to Knife's constructor

        @yaml_config_path = yaml_config_path
        config[:chef_node_name] = chef_node_name
        # Temporary fix for http://tickets.opscode.com/browse/KNIFE-103
        config[:ssh_user] = Chef::Config[:knife][:ssh_user]

        validate_profile!

        @server_create_command = Ec2ServerCreate.new
        @server_create_command.config = config_from_profile
      end

      def run
        @server_create_command.run
      end

      private

      def chef_node_name
        unless name_args.size == 1
          ui.error "NODE_NAME is mandatory"
          show_usage
          exit 1
        end

        name_args.first
      end

      # list of profile names
      def available_profiles
        @available_profiles ||= yaml_config['profiles'].map(&:first)
      end

      def validate_profile!
        unless available_profiles.include? config[:profile]
          ui.error "The profile '#{config[:profile]}' is not present in the '#{@yaml_config_path}' file. Did you make a typo?"
          exit 1
        end
      end

      def yaml_config
        @yaml_config ||= YAML.load_file(@yaml_config_path)
      end

      def profile_from_config
        @profile_from_config ||= yaml_config['profiles'][config[:profile]]
      end

      def config_from_profile
        profile_from_config.each do |key, value|
          option = key.to_sym

          config[option] = profile_from_config[key]
          msg_pair "#{option} set from #{key} in profile",
                    pretty_config(config[option])
        end
      end

      def pretty_config(config)
        return config.join(',') if config.is_a? Array

        config
      end
    end
  end
end
