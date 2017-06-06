require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_fcp).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp FCP service. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :fcplist => {:api => 'fcp-service-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :fcpcreate => 'fcp-service-create'
  netapp_commands :fcpdestroy => 'fcp-service-destroy'
  netapp_commands :fcpstart => 'fcp-service-start'
  netapp_commands :fcpstop => 'fcp-service-stop'

  mk_resource_methods

  def self.instances
    fcps = []
    results = fcplist() || []
    results.each do |fcp|
      vserver = fcp.child_get_string('vserver')
      node_name = fcp.child_get_string('node-name')
      fcp_hash = {
        :name => vserver,
        :ensure => :present,
        :node_name => node_name,
      }
 
      fcp_state = fcp.child_get_string('is-available')
      if fcp_state == 'true'
        fcp_hash[:state] = 'on'
       else
        fcp_hash[:state] = 'off'
      end

      fcps << new(fcp_hash)
    end
    fcps
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_hash[:ensure] == :absent
      fcpstop()
      fcpdestroy()
    end 
  end   
 
  def state=(value)
    case resource[:state]
    when :on
      fcpstart()
    when :off
      fcpstop()
    end
  end
  
  def create
    fcpcreate(*get_args)
    @property_hash.clear
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args
    args = Array.new
    args += ['node-name', resource[:node_name]] if resource[:node_name]
    args += ['force-node-name', resource[:force_node_name]] if resource[:force_node_name]
    args += ['start', resource[:start]] if resource[:start]
    args
  end
end
