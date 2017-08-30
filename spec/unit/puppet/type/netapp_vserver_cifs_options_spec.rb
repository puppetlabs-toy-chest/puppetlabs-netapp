require 'spec_helper'

describe Puppet::Type.type(:netapp_vserver_cifs_options) do

  before do
    @vserver_cifs_options_example = {
      :name         => 'vserverA',
      :max_mpx      => '256',
      :smb2_enabled => 'true'
    }
    described_class.provider(:cmode).new(@vserver_cifs_options_example)
  end

  let :vserver_cifs_options_resource do
    @vserver_cifs_options_example
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

    [:max_mpx, :smb2_enabled].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support a valid vserver name" do
        described_class.new(:name => 'vserverA')[:name].should == 'vserverA'
      end

      it "should support underscores" do
        described_class.new(:name => 'vserver_A')[:name].should == 'vserver_A'
      end

      it "should support hyphens" do
        described_class.new(:name => 'vserver-A')[:name].should == 'vserver-A'
      end

      it "should support an alphanumerical name" do
        described_class.new(:name => 'vserver01')[:name].should == 'vserver01'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'vserver A') }.to raise_error(Puppet::Error, /A Vserver name can only contain alphanumeric characters and ".", "-" or "_"/)
      end
    end

    describe "for max_mpx" do
      it "should support 100" do
        described_class.new(:name => 'vserverA', :max_mpx => '100')[:max_mpx].should == 100
      end

      it "should not support a number greater than 65535" do
        expect { described_class.new(:name => 'vserverA', :max_mpx => '65536') }.to raise_error(Puppet::Error, /The value for maximum simultaneous operations per TCP connection must be in between 2 to 65535./)
      end

      it "should not support a number less than 2" do
        expect { described_class.new(:name => 'vserverA', :max_mpx =>'1') }.to raise_error(Puppet::Error, /The value for maximum simultaneous operations per TCP connection must be in between 2 to 65535./)
      end

      it "should not support a alphabet" do
        expect { described_class.new(:name => 'vserverA', :max_mpx => 'abc') }.to raise_error(Puppet::Error, /abc is not a valid max-queue-depth./)
      end
    end

    describe "for smb2_enabled option" do
      it "should support true" do
        described_class.new(:name => 'vserverA', :smb2_enabled => 'true')[:smb2_enabled].should == :true
      end

      it "should support false" do
        described_class.new(:name => 'vserverA', :smb2_enabled => 'false')[:smb2_enabled].should == :false
      end

      it "should not support an invalid value" do
        expect { described_class.new(:name => 'vserverA', :smb2_enabled => 'invalid') }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
    end
  end
end
