# This plugin needs .chef/knife.rb populated with knife[:aws_access_key_id]  and knife[:aws_secret_access_key] and a config/ec2.yml file

require 'chef/knife'
require 'chef/knife/ec2_server_create'

class Chef
  class Knife
    class Ec2ServerFromProfile < Ec2ServerCreate
      YAML_CONFIG_PATH = 'config/ec2.yml'

      PROFILE_ATTRIBUTES = [
        { :config      => :run_list,
          :profile     => 'run_list',
          :description => 'Run list' },
        { :config      => :security_groups,
          :profile     => 'ec2_security_groups',
          :description => 'EC2 security groups' },
        { :config      => :environment,
          :profile     => 'chef_environment',
          :description => 'Chef environment' },
        { :config => :distro,
          :profile => 'distro',
          :description => 'Distro' }
      ]

      deps do
        require 'yaml'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 server from profile NODE_NAME --profile=PROFILE (options)"

      # Inherit options from knife-ec2 plugin
      @options = Ec2ServerCreate.options.dup

      option :profile,
             :long        => '--profile PROFILE',
             :required    => true,
             :description => "Profile to load from the #{YAML_CONFIG_PATH} file"

      def run
        config[:chef_node_name] = chef_node_name
        validate_profile!

        set_config_from_profile

        # Now let knife-ec2 do the bootstrapping
        super
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
          ui.error "The profile '#{config[:profile]}' is not present in the '#{YAML_CONFIG_PATH}' file. Did you make a typo?"
          exit 1
        end
      end

      def yaml_config
        @yaml_config ||= YAML.load_file(File.join(Dir.pwd, YAML_CONFIG_PATH))
      end

      def profile_from_config
        @profile_from_config ||= yaml_config['profiles'][config[:profile]]
      end

      def set_config_from_profile
        PROFILE_ATTRIBUTES.each do |attribute|
          config_attribute  = attribute[:config]
          profile_attribute = attribute[:profile]

          if config[config_attribute].nil?
            config[config_attribute] = profile_from_config[profile_attribute]
            msg_pair "#{attribute[:description]} set from profile",
                     pretty_config(config[config_attribute])
          end
        end
      end

      def pretty_config(config)
        return config.join(',') if config.is_a? Array

        config
      end
    end
  end
end
