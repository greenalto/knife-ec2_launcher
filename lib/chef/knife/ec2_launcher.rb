# This plugin needs .chef/knife.rb populated with knife[:aws_access_key_id]
# and knife[:aws_secret_access_key] and a config/ec2.yml file

require 'chef/knife'
require 'chef/knife/ec2_base'
require 'chef/knife/ec2_server_create'
require 'chef/knife/yaml_profiles'

class Chef
  class Knife
    class Ec2ServerFromProfile < Knife
      include Knife::Ec2Base

      deps do
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

      option :yaml_config,
             :long        => '--yaml-config PATH',
             :default     => File.join(Dir.pwd, 'config/ec2.yml'),
             :description => "Path to the YAML config file"

      # Set the config from the profile
      def initialize(argv=[])
        super(argv) # Thanks, mixlib-cli

        @profiles = YAMLProfiles.new(config[:yaml_config])
        validate_profile!

        config[:chef_node_name] = chef_node_name

        configure_chef

        # Temporary fix for http://tickets.opscode.com/browse/KNIFE-103
        config[:ssh_user]        = config_from_knife_or_default(:ssh_user)
        config[:ssh_port]        = config_from_knife_or_default(:ssh_port)
        config[:ssh_gateway]     = config_from_knife_or_default(:ssh_gateway)
        config[:identity_file]   = config_from_knife_or_default(:identity_file)
        config[:host_key_verify] = config_from_knife_or_default(:host_key_verify)
        config[:use_sudo]        = true if config[:ssh_user] != 'root'

        # Load the knife config file right away. Provided by Knife class.
        set_config_from_profile

        @server_create_command = Ec2ServerCreate.new
        @server_create_command.config = config
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

      def set_config_from_profile
        @profiles[config[:profile]].each do |key, value|
          option = key.to_sym

          config[option] = @profiles[config[:profile]][key]
          msg_pair "#{option} set from profile",
                    pretty_config(config[option])
        end
      end

      def config_from_knife_or_default(key)
        Chef::Config[:knife][key] || config[key]
      end

      def validate_profile!
        unless @profiles.all.include? config[:profile]
          ui.error "The profile '#{config[:profile]}' is not present in the "\
                   "'#{@profiles.config_file}' file. Did you make a typo?"
          exit 1
        end
      end

      def pretty_config(value)
        return value.join(',') if value.is_a? Array

        value
      end
    end
  end
end
