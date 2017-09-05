require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_system_node_autosupport).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_system_node_autosupport).stubs(:defaultprovider).returns described_class
  end

  let :system_node_autosupport do
    Puppet::Type.type(:netapp_system_node_autosupport).new(
      :name               => 'nodeA',
    )
  end

  let :provider do
    described_class.new(
      :name => 'nodeA'
    )
  end

  describe "#instances" do
    it "should return an array of current autosupport-config objects" do
      described_class.expects(:autosupportcnfglist).returns YAML.load_file(my_fixture('system-node-autosupport-list.yml'))
      instances = described_class.instances
      instances.size.should == 2
      instances.map do |prov|
        {
          :name                => prov.get(:name),
          :periodic_tx_window  => prov.get(:periodic_tx_window),
        }
      end.should == [
        {
          :name               => 'nodeA',
          :periodic_tx_window => '1h'
        },
        {
          :name               => 'nodeB',
          :periodic_tx_window => '2h'
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:autosupportcnfglist).returns YAML.load_file(my_fixture('system-node-autosupport-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify periodic_tx_window" do
      system_node_autosupport.provider.set(:name => 'nodeA',:periodic_tx_window => '3h')
      system_node_autosupport[:periodic_tx_window] ='2h'
      system_node_autosupport.provider.expects(:autosupportcnfgmdfy).with('node-name', 'nodeA', 'periodic-tx-window', '2h')
      system_node_autosupport.provider.flush
    end
  end
end
