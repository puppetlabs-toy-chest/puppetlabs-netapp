require 'spec_helper'

describe Puppet::Type.type(:netapp_cifs) do

  before do
    @cifs_example = {
      :name           => 'cifsA',
      :domain         => 'abc.com',
      :admin_username => 'abc',
      :admin_password => 'xyz',
      :ensure         => 'present'
    }
    described_class.provider(:cmode).new(@cifs_example)
  end

  let :cifs_resource do
    @cifs_example
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

    [:domain, :admin_username, :admin_password].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support a valid cifs server name" do
        described_class.new(:name => 'cifsA', :ensure => :present)[:name].should == 'cifsA'
      end

      it "should support underscores" do
        described_class.new(:name => 'cifs_A', :ensure => :present)[:name].should == 'cifs_A'
      end

      it "should support hyphens" do
        described_class.new(:name => 'cifs-A', :ensure => :present)[:name].should == 'cifs-A'
      end

      it "should support an alphanumerical name" do
        described_class.new(:name => 'cifs01', :ensure => :present)[:name].should == 'cifs01'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'cifs A', :ensure => :present) }.to raise_error(Puppet::Error, /cifs A is an invalid cifs server name./)
      end
    end
  end
end
