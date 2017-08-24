require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_storage_array).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_storage_array).stubs(:defaultprovider).returns described_class
  end

  let :netapp_storage_array do
    Puppet::Type.type(:netapp_storage_array).new(
      :name            => 'storage1',
      :provider        => provider
    )
  end

  let :provider do
    described_class.new(
      :name => 'storage1'
    )
  end

  describe "#instances" do
    it "should return an array of current storage arrays" do
      described_class.expects(:strgarrayshow).returns YAML.load_file(my_fixture('storage-array-list.yml'))
      instances = described_class.instances
      instances.size.should == 2
      instances.map do |prov|
        {
          :name      => prov.get(:name),
          :max_queue_depth => prov.get(:max_queue_depth)
        }
      end.should == [
        {
          :name      => 'storage_array_name1',
          :max_queue_depth    => 100
        },
        {
          :name      => 'storage_array_name2',
          :max_queue_depth    => 100
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:strgarrayshow).returns YAML.load_file(my_fixture('storage-array-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify max queue depth of storage array" do
      netapp_storage_array.provider.set(:name => 'storage1',:max_queue_depth => '120')
      netapp_storage_array[:max_queue_depth] ='100'
      netapp_storage_array.provider.expects(:strgarraymdfy).with('array-name', 'storage1', 'max-queue-depth', 100)
      netapp_storage_array.provider.flush
    end
  end
end
