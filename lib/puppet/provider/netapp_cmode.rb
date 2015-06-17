require 'puppet/provider/netapp'
class Puppet::Provider::NetappCmode < Puppet::Provider::Netapp
  def initialize(value={})
    super(value)
    if value.is_a? Hash
      @original_values = value.clone
    else
      @original_values = Hash.new
    end
    @create_elements = false
  end

  # Restrict to cMode
  def self.inherited(klass)
    klass.confine :true => begin
      transport && transport.get_application_name == 'puppet_netapp_cmode'
    rescue Exception
      false
    end
  end
end
