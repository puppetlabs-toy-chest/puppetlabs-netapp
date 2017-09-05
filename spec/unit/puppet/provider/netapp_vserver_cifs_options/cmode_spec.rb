require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_vserver_cifs_options).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_vserver_cifs_options).stubs(:defaultprovider).returns described_class
  end

  let :vserver_cifs_options do
    Puppet::Type.type(:netapp_vserver_cifs_options).new(
      :name         => 'vserverA',
      :max_mpx      => '10',
      :smb2_enabled => 'true'
    )
  end

  let :provider do
    described_class.new(
      :name => 'vserverA'
    )
  end

  describe "#instances" do
    it "should return an array of current cifs-options object" do
      described_class.expects(:vsrvcifsoptlist).returns YAML.load_file(my_fixture('cifs-options-list.yml'))
      instances = described_class.instances
      instances.size.should == 2
      instances.map do |prov|
        {
        :name         => prov.get(:name),
        :max_mpx      => prov.get(:max_mpx),
        :smb2_enabled => prov.get(:smb2_enabled)
        }
      end.should == [
        {
        :name         => 'vserver1',
        :max_mpx      => '10',
        :smb2_enabled => 'true'
        },
        {
        :name         => 'vserver2',
        :max_mpx      => '20',
        :smb2_enabled => 'false'
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:vsrvcifsoptlist).returns YAML.load_file(my_fixture('cifs-options-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify max_mpx" do
      vserver_cifs_options.provider.set(:name => 'vserverA', :max_mpx => '20', :smb2_enabled => 'true',)
      vserver_cifs_options[:max_mpx] = '10'
      vserver_cifs_options.provider.expects(:vsrvcifsoptmdfy).with('max-mpx', 10, 'is-smb2-enabled', :true)
      vserver_cifs_options.provider.flush
    end

    it "should be able to modify a smb2_enabled option" do
      vserver_cifs_options.provider.set(:name => 'vserverA', :max_mpx => '10', :smb2_enabled => 'false')
      vserver_cifs_options[:smb2_enabled] = 'true'
      vserver_cifs_options.provider.expects(:vsrvcifsoptmdfy).with('max-mpx', 10, 'is-smb2-enabled', :true)
      vserver_cifs_options.provider.flush
    end
  end
end
