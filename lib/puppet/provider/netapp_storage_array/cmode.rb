require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_storage_array).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage storage array. [Family: cluster]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands   :strgarrayshow  => 'storage-array-list-info'
  netapp_commands   :strgarraymdfy  => 'storage-array-modify'
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_storage_array.cmode: Got to self.instances")
    strgarrayinfos = []
    results = strgarrayshow() || []
    storage_arrays = results.child_get('array-profiles').children_get()

    storage_arrays.each do |storage_array|
      storage_array_name = storage_array.child_get_string('name')
      max_queue_depth = storage_array.child_get_string('max-queue-depth')
      strg_array_info_hash = {
        :name       => storage_array_name,
        :max_queue_depth => max_queue_depth,
        :ensure => :present
      }
      strgarrayinfos << new(strg_array_info_hash)
    end
    strgarrayinfos
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_storage_array.cmode: Got to prefetch")
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_storage_array.cmode: Got to flush for resource #{@resource[:name]}.")
    result = strgarraymdfy('array-name', @resource[:name], 'max-queue-depth', @resource[:max_queue_depth])
  end
end
