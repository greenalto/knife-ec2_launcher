require 'spec_helper'

describe Chef::Knife::Ec2ServerFromProfile do
  class DummyEc2ServerCreate
  end

  let :yaml_config_path do
    File.expand_path('../../../fixtures/config/ec2.yml', __FILE__)
  end

  let :argv do
    %w(ec2 server from profile node_name --profile=test) \
      << "--yaml-config=#{yaml_config_path}"
  end

  let :ec2_server_create do
    DummyEc2ServerCreate.new
  end

  let :launcher do
    described_class.new(argv, ec2_server_create)
  end

  context 'when passing a node_name' do
    before do
      ec2_server_create.stub :config=
      ec2_server_create.stub :run
    end

    context 'when a node_name and a profile are passed' do
      before do
        silence(:stdout) { launcher.run }
      end

      it 'sets the default options' do
        expect(launcher.options[:ssh_port][:default]).to eq '22'
      end

      it 'sets the options from the profile in the config file' do
        [
          [:security_groups, ['dev']],
          [:run_list,        ['recipe[build-essential]', 'role[base]']],
          [:environment,     'dev'],
          [:distro,          'chef-full'],
          [:image,           'ami-0dadba79'],
          [:flavor,          'm1.small']
        ].each do |config, value|
          expect(launcher.config[config]).to eq value
        end
      end
    end

    context 'when setting a ssh_user through knife options' do
      before do
        Chef::Config[:knife][:ssh_user] = 'ubuntu'
        silence(:stdout) { launcher.run }
      end

      it 'sets it correctly' do
        expect(launcher.config[:ssh_user]).to eq 'ubuntu'
      end
    end

    context 'passing valid credentials & image' do
      before do
        launcher.config[:image]             = 'ami-0dadba79'
        launcher.config[:aws_ssh_key_id]    = 'dummy'
        launcher.config[:aws_access_key_id] = 'dummy'
        launcher.config[:aws_secret_key_id] = 'dummy'

        expect(ec2_server_create).to receive(:run).and_return true
      end

      it 'runs' do
        capture(:stdout) do
          expect(launcher.run).to be_true
        end
      end

      it 'outputs the config' do
        content = capture(:stdout) { launcher.run }
        [
          'security_groups set from profile: dev',
          'run_list set from profile: recipe\[build-essential\],role\[base\]',
          'environment set from profile: dev',
          'distro set from profile: chef-full',
          'image set from profile: ami-0dadba79',
          'flavor set from profile: m1.small'
        ].each do |line|
            expect(content).to match(/#{line}/)
          end
      end
    end
  end

  context 'when passing invalid arguments' do
    context 'when no node_name is passed' do
      let :argv do
        %w(ec2 server from profile --profile=test) \
          << "--yaml-config=#{yaml_config_path}"
      end

      it 'exits the program' do
        launcher.should_receive(:show_usage).and_return true
        launcher.ui.should_receive(:fatal)
        expect { launcher.run }.to raise_error SystemExit
      end
    end

    context 'when too many args are passed' do
      let :argv do
        %w(ec2 server from profile node_name extra_param --profile=test) \
          << "--yaml-config=#{yaml_config_path}"
      end

      it 'exits the program' do
        launcher.should_receive(:show_usage).and_return true
        launcher.ui.should_receive(:fatal)
        expect { launcher.run }.to raise_error SystemExit
      end
    end
  end
end
