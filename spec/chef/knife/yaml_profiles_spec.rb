require 'spec_helper'

describe Chef::Knife::YAMLProfiles do
  let :yaml_config_path do
    File.expand_path('../../../fixtures/config/ec2.yml', __FILE__)
  end

  let :profiles do
    described_class.new(yaml_config_path)
  end

  describe '#all' do
    subject do
      profiles.all
    end

    it 'lists the profiles from the config file' do
      expect(subject).to eq ['test', 'test_2']
    end
  end

  describe '#[]' do
    subject do
      profiles['test']
    end

    it 'lists the profiles from the config file' do
      expected_config = {
        'security_groups' => ['dev'],
        'run_list'        => ['recipe[build-essential]', 'role[base]'],
        'environment'     => 'dev',
        'distro'          => 'chef-full',
        'image'           => 'ami-0dadba79',
        'flavor'          => 'm1.small'
      }
      expect(subject).to eq expected_config
    end
  end
end
