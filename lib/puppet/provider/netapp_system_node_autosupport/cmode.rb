require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_system_node_autosupport).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp system node autosupport configuration. [Family: cluster]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands   :autosupportcnfglist => {:api => 'autosupport-config-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands   :autosupportcnfgmdfy => 'autosupport-config-modify'
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_system_node_autosupport.cmode: Got to self.instances")
    autosupportcnfginfos = []
    results = autosupportcnfglist() || []

    results.each do |result|
      auto_support_config_info_hash = {
        :name               => result.child_get_string('node-name'),
        :periodic_tx_window => result.child_get_string('periodic-tx-window'),
        :ensure             => :present
       }
       autosupportcnfginfos << new(auto_support_config_info_hash)
    end
    autosupportcnfginfos
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_system_node_autosupport.cmode: Got to prefetch")
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_system_node_autosupport.cmode: Got to flush for node #{@resource[:name]}")
    autosupportcnfgmdfy("node-name", @resource[:name], "periodic-tx-window", @resource[:periodic_tx_window])
  end
end
