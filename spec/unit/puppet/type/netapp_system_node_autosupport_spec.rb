require 'spec_helper'

describe Puppet::Type.type(:netapp_system_node_autosupport) do

  before do
    @system_node_autosupport_example = {
      :name               => 'nodeA',
      :periodic_tx_window => '3h'
    }
    described_class.provider(:cmode).new(@system_node_autosupport_example)
  end

  let :system_node_autosupport_resource do
    @system_node_autosupport_example
  end

  it "should have :name be its namevar" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:periodic_tx_window].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support a valid node name" do
        described_class.new(:name => 'nodeA')[:name].should == 'nodeA'
      end

      it "should support underscores" do
        described_class.new(:name => 'node_A')[:name].should == 'node_A'
      end

      it "should support hyphens" do
        described_class.new(:name => 'node-A')[:name].should == 'node-A'
      end

      it "should support an alphanumerical node name" do
        described_class.new(:name => 'node01')[:name].should == 'node01'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'node A') }.to raise_error(Puppet::Error, /node A is a invalid node name/)
      end
    end
  end
end
