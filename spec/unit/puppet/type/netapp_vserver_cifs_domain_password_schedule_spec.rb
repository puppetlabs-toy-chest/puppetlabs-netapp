require 'spec_helper'

describe Puppet::Type.type(:netapp_vserver_cifs_domain_password_schedule) do

  before do
    @vserver_cifs_domain_password_schedule_example = {
      :name                       => 'vserverA',
      :schedule_randomized_minute => '100'
    }
    described_class.provider(:cmode).new(@vserver_cifs_domain_password_schedule_example)
  end

  let :vserver_cifs_domain_password_schedule_resource do
    @vserver_cifs_domain_password_schedule_example
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

    [:schedule_randomized_minute].each do |prop|
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

    describe "for schedule_randomized_minute" do
      it "should support 100" do
        described_class.new(:name => 'vserverA', :schedule_randomized_minute => '100')[:schedule_randomized_minute].should == 100
      end

      it "should not support a number greater than 180" do
        expect { described_class.new(:name => 'vserverA', :schedule_randomized_minute => '181') }.to raise_error(Puppet::Error, /Schedule randomized minute value must be in between 1 and 180./)
      end

      it "should not support a number less than 1" do
        expect { described_class.new(:name => 'vserverA', :schedule_randomized_minute =>'0') }.to raise_error(Puppet::Error, /Schedule randomized minute value must be in between 1 and 180./)
      end

      it "should not support a alphabet" do
        expect { described_class.new(:name => 'vserverA', :schedule_randomized_minute => 'abc') }.to raise_error(Puppet::Error, /abc is not a valid schedule randomized minute./)
      end
    end
  end
end
