require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_storage_failover).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_storage_failover).stubs(:defaultprovider).returns described_class
  end

  let :storage_array do
    Puppet::Type.type(:netapp_storage_failover).new(
      :name     => 'nodeA',
      :provider => provider
    )
  end

  let :provider do
    described_class.new(
      :name => 'nodeA'
    )
  end

  describe "#instances" do
    it "should return an array of current cf objects" do
      described_class.expects(:strgfailovershow).returns YAML.load_file(my_fixture('storage-failover-list.yml'))
      instances = described_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
          :name      => prov.get(:name),
          :auto_giveback => prov.get(:auto_giveback),
          :auto_giveback_after_panic => prov.get(:auto_giveback_after_panic),
          :auto_giveback_override_vetoes => prov.get(:auto_giveback_override_vetoes),

        }
      end.should == [
        {
          :name                          => 'nodeA',
          :auto_giveback                 => 'true',
          :auto_giveback_after_panic     => 'true',
          :auto_giveback_override_vetoes => 'true'
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:strgfailovershow).returns YAML.load_file(my_fixture('storage-failover-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify auto_giveback option" do
      storage_array.provider.set(:name => 'nodeA', :auto_giveback => 'true')
      storage_array[:auto_giveback] = 'false'
      storage_array.provider.expects(:strgfailovermdfy).with(is_a(NaElement))
      storage_array.provider.flush
    end

    it "should be able to modify auto_giveback_after_panic option" do
      storage_array.provider.set(:name => 'nodeA', :auto_giveback_after_panic => 'true')
      storage_array[:auto_giveback_after_panic] = 'false'
      storage_array.provider.expects(:strgfailovermdfy).with(is_a(NaElement))
      storage_array.provider.flush
    end

    it "should be able to modify auto_giveback_override_vetoes option" do
      storage_array.provider.set(:name => 'nodeA', :auto_giveback_override_vetoes => 'true')
      storage_array[:auto_giveback_override_vetoes] = 'false'
      storage_array.provider.expects(:strgfailovermdfy).with(is_a(NaElement))
      storage_array.provider.flush
    end
  end
end
