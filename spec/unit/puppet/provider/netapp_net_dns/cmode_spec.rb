require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_net_dns).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_net_dns).stubs(:defaultprovider).returns described_class
  end

  let :net_dns do
    Puppet::Type.type(:netapp_net_dns).new(
      :name         => 'vserver01',
      :ensure       => :present,
      :provider     => provider
    )
  end

  let :provider do
    described_class.new(
      :name => 'vserver01'
    )
  end

  describe "#instances" do
    it "should return an array of current dns server" do
      described_class.expects(:netdnsoptlist).returns YAML.load_file(my_fixture('net-dns-list.yml'))
      instances = described_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
        :name         => prov.get(:name),
        :domains      => prov.get(:domains),
        :state        => prov.get(:state),
        :name_servers => prov.get(:name_servers),
        :ensure       => prov.get(:ensure)
        }
      end.should == [
        {
        :name         => 'vserver01',
        :domains      => ['domain1.com', 'domain2.com', 'domain3.com'],
        :state        => 'enabled',
        :name_servers => ['10.10.10.10', '10.10.10.11', '10.10.10.12'],
        :ensure       => :present
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:netdnsoptlist).returns YAML.load_file(my_fixture('net-dns-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when asking exists?" do
    it "should return true if resource is present" do
      net_dns.provider.set(:ensure => :present)
      net_dns.provider.should be_exists
    end

    it "should return false if resource is absent" do
      net_dns.provider.set(:ensure => :absent)
      net_dns.provider.should_not be_exists
    end
  end

  describe "when creating a resource" do
    it "should be able to create a dns" do
      net_dns.provider.expects(:netdnscreate).with(is_a(NaElement)).returns YAML.load_file(my_fixture('net-dns-response.yml'))
      net_dns.provider.create
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify domains" do
      net_dns.provider.set(:name => 'vserver01', :ensure => :present, :domains => ["abc", "def.com"])
      net_dns[:domains] = ['abc.com', 'xyz.com']
      net_dns.provider.expects(:netdnsmdfy).with(is_a(NaElement))
      net_dns.provider.flush
    end

    it "should be able to modify a dns state" do
      net_dns.provider.set(:name => 'vserver01', :ensure => :present, :state => 'enabled')
      net_dns[:state] = 'disabled'
      net_dns.provider.expects(:netdnsmdfy).with(is_a(NaElement))
      net_dns.provider.flush
    end

    it "should be able to modify name servers" do
      net_dns.provider.set(:name => 'vserver01', :ensure => :present, :name_servers => ['10.193.0.150'])
      net_dns[:name_servers] = ['10.193.0.250']
      net_dns.provider.expects(:netdnsmdfy).with(is_a(NaElement))
      net_dns.provider.flush
    end
  end
end
