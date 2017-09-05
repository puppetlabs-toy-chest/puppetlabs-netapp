require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_cifs).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_cifs).stubs(:defaultprovider).returns described_class
  end

  let :cifs do
    Puppet::Type.type(:netapp_cifs).new(
      :name           => 'cifs01',
      :ensure         => 'present',
      :domain         => 'domain.local',
      :admin_username => 'username',
      :admin_password => 'password',
      :provider       => provider
    )
  end

  let :provider do
    described_class.new(
      :name => 'cifs01'
    )
  end

  describe "#instances" do
    it "should return an array of current cifs server" do
      described_class.expects(:cifslist).returns YAML.load_file(my_fixture('cifs-list.yml'))
      instances = described_class.instances
      instances.size.should == 2 
      instances.map do |prov|
        {
        :name         => prov.get(:name),
        :domain       => prov.get(:domain),
        :ensure       => prov.get(:ensure)
        }
      end.should == [
        {
        :name         => 'cifs01',
        :domain       => 'abc.local',
        :ensure       => :present
        },
        {
        :name         => 'cifs02',
        :domain       => 'xyz.local',
        :ensure       => :present
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:cifslist).returns YAML.load_file(my_fixture('cifs-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when asking exists?" do
    it "should return true if resource is present" do
      cifs.provider.set(:ensure => :present)
      cifs.provider.should be_exists
    end

    it "should return false if resource is absent" do
      cifs.provider.set(:ensure => :absent)
      cifs.provider.should_not be_exists
    end
  end

  describe "when creating a resource" do
    it "should be able to create a cifs server" do
      cifs.provider.expects(:cifscreate).with('cifs-server', 'cifs01', 'domain', 'domain.local', 'admin-username', 'username', 'admin-password', 'password')
      cifs.provider.create
    end
  end

  describe "when destroying a resource" do
    it "should be able to destroy a cifs server" do
      cifs.provider.expects(:cifsdelete).with('admin-username', 'username', 'admin-password', 'password')
      cifs.provider.destroy
      cifs.provider.flush
    end
  end
end
