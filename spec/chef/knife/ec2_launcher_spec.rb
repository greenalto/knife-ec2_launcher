require 'spec_helper'

describe Chef::Knife::Ec2ServerFromProfile do
  let :yaml_config_path do
    File.expand_path('../../../fixtures/config/ec2.yml', __FILE__)
  end

  let :launcher do
    described_class.new(%w(ec2 server from profile node_name --profile=test), yaml_config_path)
  end

  it 'gets the options from Chef::Knife::Ec2ServerCreate' do
    launcher.options[:ssh_port][:default].should == '22'
  end

  it 'sets the options from the profile in the config file' do
    launcher.config[:security_groups].should == %w(dev)
    launcher.config[:run_list].should == %w(recipe[build-essential] role[base])
    launcher.config[:environment].should == 'prod'
    launcher.config[:distro].should == 'chef-full'
    launcher.config[:image].should == 'ami-0dadba79'
    launcher.config[:flavor].should == 'm1.small'
  end

  context 'when passing a ssh_user through knife options' do
    before do
      Chef::Config[:knife][:ssh_user] = 'ubuntu'
    end

    it 'sets it correctly' do
      launcher.config[:ssh_user].should == 'ubuntu'
    end
  end

  describe '#run' do
    subject do
      launcher.run
    end

    context 'when passing valid credentials & image' do
      before do
        launcher.config[:image] = 'ami-0dadba79'
        launcher.config[:aws_ssh_key_id] = 'dummy'
        launcher.config[:aws_access_key_id] = 'dummy'
        launcher.config[:aws_secret_key_id] = 'dummy'
      end

      it 'runs' do
        Chef::Knife::Ec2ServerCreate.any_instance.should_receive(:run).
          and_return true

        subject.should be_true
      end
    end

    context 'when passing invalid credentials & image' do
      before do
        launcher.config[:image] = 'dummy'
        launcher.config[:aws_ssh_key_id] = 'dummy'
        launcher.config[:aws_access_key_id] = 'dummy'
        launcher.config[:aws_secret_key_id] = 'dummy'
      end

      it 'raises an exception and exits' do
        expect { subject }.to raise_error SystemExit
      end
    end
  end
end
