require 'spec_helper'

describe Puppet::Type.type(:netapp_storage_array) do

  before do
    @storage_array_example = {
      :name              => 'VMware_Virtualdisk_1',
      :max_queue_depth   => '256'
    }
    described_class.provider(:cmode).new(@storage_array_example)
  end

  let :storage_array_resource do
    @storage_array_example
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

    [:max_queue_depth].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support a valid storage array  name" do
        described_class.new(:name => 'storage1')[:name].should == 'storage1'
      end

      it "should support underscores" do
        described_class.new(:name => 'storage_1')[:name].should == 'storage_1'
      end

      it "should not support hyphens" do
        expect { described_class.new(:name => 'storage-1') }.to raise_error(Puppet::Error, /storage-1 is an invalid storage array name./)
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'storage 1') }.to raise_error(Puppet::Error, /storage 1 is an invalid storage array name/)
      end
    end

    describe "for max queue depth" do
      it "should support 100" do
        described_class.new(:name => 'storage', :max_queue_depth => '100')[:max_queue_depth].should == 100
      end

      it "should not support a number greater than 2048" do
        expect { described_class.new(:name => 'storage', :max_queue_depth => '2049') }.to raise_error(Puppet::Error, /max-queue-depth must be between 8 and 2048./)
      end

      it "should not support a number less than 8" do
        expect { described_class.new(:name => 'storage', :max_queue_depth =>'7') }.to raise_error(Puppet::Error, /max-queue-depth must be between 8 and 2048./)
      end

      it "should not support a alphabet" do
        expect { described_class.new(:name => 'storage', :max_queue_depth => 'abc') }.to raise_error(Puppet::Error, /abc is not a valid max-queue-depth./)
      end
    end
  end
end
