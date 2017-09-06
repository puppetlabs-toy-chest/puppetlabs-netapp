require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_net_port).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp network port. [Family: cluster]"
  
  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :netportlist => {:api => 'net-port-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :netportmdfy => 'net-port-modify'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_net_port.cmode self.instances: Got to self.instances.")
    results = netportlist() || []
    netportinfos = []

    results.each do |result|
      node_name1 = result.child_get_string('node')
      port_name1 = result.child_get_string('port')
      node_port_name = node_name1 + "@" + port_name1

      net_port_info_hash = {
        :name              => node_port_name,
        :flowcontrol_admin => result.child_get_string('administrative-flowcontrol'),
        :ensure            => :present
      }
      netportinfos << new(net_port_info_hash)
    end
    netportinfos
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_net_port.cmode: Got to self.prefetch.")
    instances.each do |prov|
      if resource = resources[prov.node_port_name]
        resource.provider = prov
      end
    end
  end

  def flush
    nodeport_name = @resource[:node_port_name]
    nodeport = nodeport_name.split("@")	
    node = nodeport[0]
    port = nodeport[1]
    Puppet.debug("Puppet::Provider::Netapp_net_port.cmode: Got to flush for port #{port} on node #{node}.")
    netportmdfy("node", node, "port", port, "administrative-flowcontrol", @resource[:flowcontrol_admin])
  end
end
