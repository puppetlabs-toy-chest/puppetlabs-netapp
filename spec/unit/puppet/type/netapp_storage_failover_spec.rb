require 'spec_helper'

describe Puppet::Type.type(:netapp_storage_failover) do

  before do
    @storage_failover_example = {
      :name                          => 'nodeA',
      :auto_giveback                 => 'false',
      :auto_giveback_after_panic     => 'false',
      :auto_giveback_override_vetoes => 'false'
    }
    described_class.provider(:cmode).new(@storage_failover_example)
  end

  let :storage_failover_resource do
    @storage_failover_example
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

    [:auto_giveback, :auto_giveback_after_panic, :auto_giveback_override_vetoes].each do |prop|
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

    describe "for auto_giveback" do
      it "should support true" do
        described_class.new(:name => 'nodeA', :auto_giveback => 'true')[:auto_giveback].should == :true
      end

      it "should support false" do
        described_class.new(:name => 'nodeA', :auto_giveback => 'false')[:auto_giveback].should == :false
      end

      it "should not support an invalid value" do
        expect { described_class.new(:name => 'nodeA', :auto_giveback => 'invalid') }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
    end

    describe "for auto_giveback_after_panic" do
      it "should support true" do
        described_class.new(:name => 'nodeA', :auto_giveback_after_panic => 'true')[:auto_giveback_after_panic].should == :true
      end

      it "should support false" do
        described_class.new(:name => 'nodeA', :auto_giveback_after_panic => 'false')[:auto_giveback_after_panic].should == :false
      end

      it "should not support an invalid value" do
        expect { described_class.new(:name => 'nodeA', :auto_giveback_after_panic => 'invalid') }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
    end

    describe "for auto_giveback_override_vetoes" do
      it "should support true" do
        described_class.new(:name => 'nodeA', :auto_giveback_override_vetoes => 'true')[:auto_giveback_override_vetoes].should == :true
      end

      it "should support false" do
        described_class.new(:name => 'nodeA', :auto_giveback_override_vetoes => 'false')[:auto_giveback_override_vetoes].should == :false
      end

      it "should not support an invalid value" do
        expect { described_class.new(:name => 'nodeA', :auto_giveback_override_vetoes => 'invalid') }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
    end
  end
end
