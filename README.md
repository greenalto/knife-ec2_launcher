# Knife EC2 Launcher

A knife-ec2 wrapper with support for YAML profiles

## Installation

Add this line to your application's Gemfile:

    gem 'knife-ec2_launcher', :git => 'git@github.com:greenalto/knife-ec2_launcher.git'

And then execute:

    $ bundle

## Usage

Create a config/ec2.yml file in your Chef repository. Here's an example:

    profiles:
      svn:
        ec2_security_groups:
          - "svn"
        run_list:
          - "role[svn]"
          - "role[base]"

      nfs_server:
        ec2_security_groups:
          - "cove"
        run_list:
          - "role[base]"
          - "role[nfs_server]"
        chef_environment: "prod"
        distro: "ubuntu12.04-gems"

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
