require 'spec_helper'

describe Puppet::Type.type(:netapp_net_dns) do

  before do
    @net_dns_example = {
      :name         => 'vserver01',
      :domains      => ['abc.com', 'xyz.com'],
      :state        => 'enabled',
      :name_servers => '10.193.0.250'      
    }
    described_class.provider(:cmode).new(@net_dns_example)
  end

  let :net_dns_resource do
    @net_dns_example
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

    [:domains, :name_servers, :state,].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support a valid vserver name" do
        described_class.new(:name => 'vserverA', :ensure => :present)[:name].should == 'vserverA'
      end

      it "should support underscores" do
        described_class.new(:name => 'vserver_A', :ensure => :present)[:name].should == 'vserver_A'
      end

      it "should support hyphens" do
        described_class.new(:name => 'vserver-A', :ensure => :present)[:name].should == 'vserver-A'
      end

      it "should support an alphanumerical name" do
        described_class.new(:name => 'vserver01', :ensure => :present)[:name].should == 'vserver01'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'vserver A', :ensure => :present) }.to raise_error(Puppet::Error, /A Vserver name can only contain alphanumeric characters and ".", "-" or "_"/)
      end
    end
 
    describe "for domains" do
      it "should support an array" do
        described_class.new(:name => 'vserver01', :domains => ['abc.com', 'xyz.com'], :ensure => :present)[:domains].should == ['abc.com','xyz.com']
      end

      it "should support a value" do
        described_class.new(:name => 'vserver01', :domains => 'abc.com', :ensure => :present)[:domains].should == ['abc.com']
      end
    end

    describe "for name_servers" do
      it "should support an array" do
        described_class.new(:name => 'vserver01', :name_servers => ['10.193.0.250', '10.193.0.150'], :ensure => :present)[:name_servers].should == ['10.193.0.250', '10.193.0.150']
      end

      it "should support an IPv4 address" do
         described_class.new(:name => 'vserver01', :name_servers => '10.193.0.250', :ensure => :present)[:name_servers].should == ['10.193.0.250']
      end

      it "should not support value other than an IPv4 address" do
        expect { described_class.new(:name => 'vserver01', :name_servers => '100', :ensure => :present) }.to raise_error(Puppet::Error, /100 is an invalid value for field name-servers/)
      end

      it "should not support an IPv6 address" do
        expect { described_class.new(:name => 'vserver01', :name_servers => '2001:0db8:85a3:0000:0000:8a2e:0370:7334', :ensure => :present) }.to raise_error(Puppet::Error, /2001:0db8:85a3:0000:0000:8a2e:0370:7334 is an invalid value for field name-servers/)
      end
    end

    describe "for state" do
      it "should support enabled" do
        described_class.new(:name => 'vserver01', :state => 'enabled', :ensure => :present)[:state].should == :enabled
      end

      it "should support disabled" do
        described_class.new(:name => 'vserver01', :state => 'disabled', :ensure => :present)[:state].should == :disabled
      end

      it "should not support an invalid value" do
        expect { described_class.new(:name => 'vserver01', :state => 'invalid', :ensure => :present) }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
    end
  end
end
