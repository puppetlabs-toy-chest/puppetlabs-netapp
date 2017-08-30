require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_net_port).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_net_port).stubs(:defaultprovider).returns described_class
  end

  let :net_port do
    Puppet::Type.type(:netapp_net_port).new(
      :node_port_name  => 'node@port',
      :provider        => provider
    )
  end

  let :provider do
    described_class.new(
      :node_port_name => 'node@port'
    )
  end

  describe "#instances" do
    it "should return an array of current network ports" do
      described_class.expects(:netportlist).returns YAML.load_file(my_fixture('net-port-list.yml'))
      instances = described_class.instances
      instances.size.should == 2
      instances.map do |prov|
        {
          :node_port_name    => prov.get(:node_port_name),
          :flowcontrol_admin => prov.get(:flowcontrol_admin)
        }
      end.should == [
        {
          :node_port_name    => 'node_name1@port1',
          :flowcontrol_admin => "full"
        },
        {
          :node_port_name    => 'node_name2@port2',
          :flowcontrol_admin => "full"
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:netportlist).returns YAML.load_file(my_fixture('net-port-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify the flowcontrol admin value of a port" do
      net_port.provider.set(:node_port_name => 'node@port', :flowcontrol_admin => 'full')
      net_port[:flowcontrol_admin] ='receive'
      net_port.provider.expects(:netportmdfy).with('node', 'node', 'port', 'port', 'administrative-flowcontrol', :receive)
      net_port.provider.flush
    end
  end
end
