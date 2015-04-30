require 'puppet/provider/netapp'
class Puppet::Provider::NetappCmode < Puppet::Provider::Netapp
  # Restrict to cMode
  def self.inherited(klass)
    klass.confine :true => begin
      transport && transport.get_application_name == 'puppet_netapp_cmode'
    rescue Exception
      false
    end
  end
end
