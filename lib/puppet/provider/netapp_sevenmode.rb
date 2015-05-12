require 'puppet/provider/netapp'
class Puppet::Provider::NetappSevenmode < Puppet::Provider::Netapp
  # Only run in 7Mode
  def self.inherited(klass)
    klass.confine :true => begin
      transport && transport.get_application_name == 'puppet_netapp_sevenmode'
    rescue Exception
      false
    end
  end
end
