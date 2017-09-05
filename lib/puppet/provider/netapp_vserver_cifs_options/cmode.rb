require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_vserver_cifs_options).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp vserver CIFS options. [Family: vserver]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :vsrvcifsoptlist => {:api => 'cifs-options-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :vsrvcifsoptmdfy => 'cifs-options-modify'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_vserver_cifs_options.cmode self.instances: Got to self.instances.")

    vserver_cifs_infos = []
    results = vsrvcifsoptlist() || []

    results.each do |result|
      vserver_cifs_info_hash = {
        :name         => result.child_get_string('vserver'),
        :max_mpx      => result.child_get_string('max-mpx'),
        :smb2_enabled => result.child_get_string('is-smb2-enabled')
      }

    vserver_cifs_infos << new(vserver_cifs_info_hash)
    end
    vserver_cifs_infos 
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_vserver_cifs_options.cMode: Got to self.prefetch.")
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_vserver_cifs_options.cMode flush: Got to flush for resource #{@resource[:name]}.")
    vsrvcifsoptmdfy('max-mpx', @resource[:max_mpx], 'is-smb2-enabled', @resource[:smb2_enabled])
    Puppet.debug("CIFS options modified successfully for vserver #{@resource[:name]}")
  end 
end
