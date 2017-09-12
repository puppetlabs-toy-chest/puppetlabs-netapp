require 'spec_helper'

describe Puppet::Type.type(:netapp_net_port) do

  before do
    @net_port_example = {
      :node_port_name    => 'node@port',
      :flowcontrol_admin => 'full'
    }
    described_class.provider(:cmode).new(@net_port_example)
  end

  let :net_port_resource do
    @net_port_example
  end

  it "should have :node_port_name be its namevar" do
    described_class.key_attributes.should == [:node_port_name]
  end

  describe "when validating attributes" do
    [:node_port_name].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:flowcontrol_admin].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for node_port_name" do
      it "node and port name should concatenated with @" do
        described_class.new(:node_port_name => 'node@port')[:node_port_name].should == 'node@port'
      end

      it "node and port name should concatenated with only one @" do
        expect { described_class.new(:node_port_name => 'node@@port') }.to raise_error(Puppet::Error, /node@@port is an invalid node_port name. Please note: node and port name should follow format node@port./)
      end

      it "node_port_name should not support space" do
        expect { described_class.new(:node_port_name => 'node @port') }.to raise_error(Puppet::Error, /node @port is an invalid node_port name. Please note: node and port name should follow format node@port./)
      end

      it "node name should support underscores" do
        described_class.new(:node_port_name => 'node_a@port')[:node_port_name].should == 'node_a@port'
      end

      it "node name should support hyphens" do
        described_class.new(:node_port_name => 'node-a@port')[:node_port_name].should == 'node-a@port'
      end

      it "node name should support an alphanumerical name" do
        described_class.new(:node_port_name => 'node123@port')[:node_port_name].should == 'node123@port'
      end

      it "port name should support an alphanumerical name" do
        described_class.new(:node_port_name => 'node@port123')[:node_port_name].should == 'node@port123'
      end

      it "port name should not support underscores" do
        expect { described_class.new(:node_port_name => 'node@port_a') }.to raise_error(Puppet::Error, /node@port_a is an invalid node_port name. Please note: node and port name should follow format node@port./)
      end

      it "port name should not support hyphens" do
        expect { described_class.new(:node_port_name => 'node@port-a') }.to raise_error(Puppet::Error, /node@port-a is an invalid node_port name. Please note: node and port name should follow format node@port./)
      end
    end

    describe "for flowcontrol_admin" do
      it "should support none" do
        described_class.new(:node_port_name => 'node@port', :flowcontrol_admin => 'none')[:flowcontrol_admin].should == :none
      end

      it "should support receive" do
        described_class.new(:node_port_name => 'node@port', :flowcontrol_admin => 'receive')[:flowcontrol_admin].should == :receive
      end

      it "should support send" do
        described_class.new(:node_port_name => 'node@port', :flowcontrol_admin => 'send')[:flowcontrol_admin].should == :send
      end

      it "should support full" do
        described_class.new(:node_port_name => 'node@port', :flowcontrol_admin => 'full')[:flowcontrol_admin].should == :full
      end

      it "should not support an invalid value" do
        expect { described_class.new(:node_port_name => 'node@port', :flowcontrol_admin => 'invalid') }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
    end
  end
end
