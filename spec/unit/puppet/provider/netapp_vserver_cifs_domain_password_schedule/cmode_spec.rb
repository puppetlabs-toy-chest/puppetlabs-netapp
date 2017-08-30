require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_vserver_cifs_domain_password_schedule).provider(:cmode) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_vserver_cifs_domain_password_schedule).stubs(:defaultprovider).returns described_class
  end

  let :vserver_cifs_domain_password_schedule do
    Puppet::Type.type(:netapp_vserver_cifs_domain_password_schedule).new(
      :name     => 'vserverA',
      :provider => provider
    )
  end

  let :provider do
    described_class.new(
      :name => 'vserverA'
    )
  end

  describe "#instances" do
    it "should return an array of current cifs-domain-password-schedule objects" do
      described_class.expects(:cifs_domain_password_schedulelist).returns YAML.load_file(my_fixture('vserver-cifs-domain-password-schedule-list.yml'))
      instances = described_class.instances
      instances.size.should == 2
      instances.map do |prov|
        {
          :name                       => prov.get(:name),
          :schedule_randomized_minute => prov.get(:schedule_randomized_minute)
        }
      end.should == [
        {
          :name                       => 'vserverA',
          :schedule_randomized_minute => '100'
        },
        {
          :name                       => 'vserverB',
          :schedule_randomized_minute => '150'
        }
      ]
    end
  end

  describe "#prefetch" do
    it "exists" do
      described_class.expects(:cifs_domain_password_schedulelist).returns YAML.load_file(my_fixture('vserver-cifs-domain-password-schedule-list.yml'))
      described_class.prefetch({})
    end
  end

  describe "when modifying a resource" do
    it "should be able to modify schedule randomized minute" do
      vserver_cifs_domain_password_schedule.provider.set(:name => 'vserverA',:schedule_randomized_minute=> '120')
      vserver_cifs_domain_password_schedule[:schedule_randomized_minute] ='100'
      vserver_cifs_domain_password_schedule.provider.expects(:cifs_domain_password_schedulemodify).with('schedule-randomized-minute', 100)
      vserver_cifs_domain_password_schedule.provider.flush
    end
  end
end
