require 'spec_helper'

describe Puppet::Type.type(:netapp_qtree) do

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :providerclass do
    described_class.provide(:fake_netapp_qtree_provider) { mk_resource_methods }
  end

  it "should have :qtname be its namevar" do
    described_class.key_attributes.should == [:qtname, :volume]
  end

  describe "when validating attributes" do
    [:qtname, :provider, :volume].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support an alphanumerical name" do
        described_class.new(:title => 'qtree01a', :ensure => :present)[:qtname].should == 'qtree01a'
      end

      it "should support a volume and directory name" do
        expect(described_class.new(:title => '/volume/dir1', :ensure => :present)[:qtname]).to eq('dir1')
        expect(described_class.new(:title => '/volume/dir1', :ensure => :present)[:volume]).to eq('volume')
      end

      it "supports composite namevars" do
        resource = described_class.new(:title => '/volume/dir1', :ensure => :present)
        expect(resource[:qtname]).to eq("dir1")
        expect(resource[:volume]).to eq("volume")
      end

      it "should not support a nested directory" do
        expect { described_class.new(:title => 'dir1/dir2', :ensure => :present) }.to raise_error(Puppet::Error, /dir1\/dir2 is not a valid qtree name/)
      end

      it "should support underscores" do
        described_class.new(:title => 'foo_bar', :ensure => :present)[:qtname].should == 'foo_bar'
      end

      it "should support hyphens" do
        described_class.new(:title => 'abc-def', :ensure => :present)[:qtname].should == 'abc-def'
      end

      it "should not support spaces" do
        expect { described_class.new(:title => 'qtree 1', :ensure => :present) }.to raise_error(Puppet::Error, /qtree 1 is not a valid qtree name/)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:title => 'q1', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:title => 'q1', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:title => 'q1', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end
    end

    describe "for volume" do
      it "should support a simple name" do
        described_class.new(:title => 'q1', :volume => 'vol1', :ensure => :present)[:volume].should == 'vol1'
      end

      it "should not support spaces" do
        expect { described_class.new(:title => 'q1', :volume => 'vol 1', :ensure => :present) }.to raise_error(Puppet::Error, /vol 1 is not a valid volume name/)
      end
    end

    describe "foo qtname" do
      it "should support an alphanumerical name" do
        described_class.new(:title => 'qtree01a', :ensure => :present)[:qtname].should == 'qtree01a'
      end

      it "should not support a nested directory" do
        expect { described_class.new(:title => 'dir1/dir2', :ensure => :present) }.to raise_error(Puppet::Error, /dir1\/dir2 is not a valid qtree name/)
      end

      it "should support underscores" do
        described_class.new(:title => 'foo_bar', :ensure => :present)[:qtname].should == 'foo_bar'
      end

      it "should support hyphens" do
        described_class.new(:title => 'abc-def', :ensure => :present)[:qtname].should == 'abc-def'
      end

      it "should not support spaces" do
        expect { described_class.new(:title => 'qtree 1', :ensure => :present) }.to raise_error(Puppet::Error, /qtree 1 is not a valid qtree name/)
      end
    end
  end

  describe "autorequiring" do
    let :qtree do
      described_class.new(
        :title   => 'q1',
        :ensure => :present,
        :volume => 'vol1'
      )
    end

    let :volumeprovider do
      Puppet::Type.type(:netapp_volume).provide(:fake_netapp_volume_provider) { mk_resource_methods }
    end

    let :volume do
      Puppet::Type.type(:netapp_volume).new(
        :title   => 'vol1',
        :ensure => :present
      )
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:netapp_volume).stubs(:defaultprovider).returns volumeprovider
    end

    it "should not autorequire a volume when no matching volume can be found" do
      catalog.add_resource qtree
      qtree.autorequire.should be_empty
    end

    it "should autorequire a matching group" do
      catalog.add_resource qtree
      catalog.add_resource volume
      reqs = qtree.autorequire
      reqs.size.should == 1
      reqs[0].source.must == volume
      reqs[0].target.must == qtree
    end
  end
end
