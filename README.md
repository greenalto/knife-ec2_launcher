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
        flavor: "t1.micro"
        image: "ami-f5998981"

      nfs_server:
        ec2_security_groups:
          - "cove"
        run_list:
          - "role[base]"
          - "role[nfs_server]"
        chef_environment: "prod"
        distro: "ubuntu12.04-gems"

You can override anything that can be set when bootstrapping a node using
knife-ec2. See
[ec2_base](https://github.com/opscode/knife-ec2/blob/201850a938b3bece4719045786619ed9ad27ff0d/lib/chef/knife/ec2_base.rb#L37-L53)
and
[ec2_server_create](https://github.com/opscode/knife-ec2/blob/master/lib/chef/knife/ec2_server_create.rb#L42-L223)
for a complete reference.

If you don't specify something in the profile, it is going to be taken from
your `.chef/knife.rb` or the defaults from the knife-ec2 plugin. For example:

    knife[:flavor] = 'm1.small'
    knife[:ssh_user] = 'ubuntu'

At the time of this writing:

* `aws_access_key_id`
* `aws_secret_key_id`
* `region`
* `flavor`
* `image`
* `security_groups`
* `security_group_ids`
* `associate_eip`
* `tags`
* `availability_zone`
* `chef_node_name`
* `ssh_key_name`
* `ssh_user`
* `ssh_password`
* `ssh_port`
* `ssh_gateway`
* `identity_file`
* `prerelease`
* `bootstrap_version`
* `distro`
* `template_file`
* `ebs_size`
* `ebs_optimized`
* `ebs_no_delete_on_term`
* `run_list`
* `json_attributes`
* `subnet_id`
* `private_ip_address`
* `host_key_verify`
* `bootstrap_protocol`
* `fqdn`
* `aws_user_data`
* `hint`
* `ephemeral`
* `server_connect_attribute`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
