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
      def initialize(argv=[], ec2_server_create=Ec2ServerCreate.new)
        super(argv) # Thanks, mixlib-cli

        # This loads the config
        configure_chef

        @profiles          = YAMLProfiles.new(config[:yaml_config])
        @ec2_server_create = ec2_server_create
      end

      def run
        config[:chef_node_name] = chef_node_name
        validate_profile!

        work_around_chef_10_bug
        set_config_from_profile

        @ec2_server_create.config = config
        @ec2_server_create.run
      end

      private

      # http://tickets.opscode.com/browse/KNIFE-103 was closed, this bug is
      # fixed in Chef 11.
      def work_around_chef_10_bug
        return if Chef::VERSION >= "11.0.0"

        [:ssh_user, :ssh_port, :ssh_gateway, :identity_file,
         :host_key_verify].each do |attribute|
          config[attribute] = config_from_knife_or_default attribute
        end
      end

      def chef_node_name
        unless name_args.size == 1
          show_usage
          ui.fatal "NODE_NAME is mandatory"
          exit 1
        end

        # We need a string, not an array of 1 string
        name_args.first
      end

      def set_config_from_profile
        @profiles[config[:profile]].each do |key, value|
          option = key.to_sym

          value = @profiles[config[:profile]][key]
          config[option] = value
          msg_pair "#{key} set from profile", pretty_config(value)
        end
      end

      def config_from_knife_or_default(key)
        Chef::Config[:knife][key] || config[key]
      end

      def validate_profile!
        unless @profiles.all.include? config[:profile]
          ui.fatal "The profile '#{config[:profile]}' is not present in the "\
                   "'#{@profiles.config_file}' file. Did you make a typo?"
          exit 1
        end
      end

      def pretty_config(value)
        Array(value).join(',')
      end
    end
  end
end
