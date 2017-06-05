require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_lun_map).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Lun map creation and deletion. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :lun_maplist => {:api => 'lun-map-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :lun_map     => 'lun-map'
  netapp_commands :lun_unmap   => 'lun-unmap'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Got to self.instances.")
    lunmaps = []

    #Get a list of all Lun maps
    results = lun_maplist()

    # Itterate through the results
    results.each do |map|
      lunmap_path = map.child_get_string('path')
      lunmap_id = map.child_get_string('lun-id')
      Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Processing lun map ID #{lunmap_id} on Lun #{lunmap_path}.")
      lunmap_name = "#{lunmap_path}:#{lunmap_id}"

      # Get the initiator group
      lunmap_initiator_group = map.child_get_string('initiator-group')

      # Construct the lunmap hash
      lunmap_hash = {
        :lunmap         => lunmap_name,
        :ensure         => :present,
        :initiatorgroup => lunmap_initiator_group
      }

      # Create the instance and add to lunmaps array
      Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Creating instance for #{lunmap_name}\n Contents = #{lunmap_hash.inspect}.")
      lunmaps << new(lunmap_hash)
    end unless results.nil?

    # Return the final lunmaps array
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Returning lunmaps array.")
    lunmaps
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.lunmap = #{resources[prov.lunmap]}. ")
      if resource = resources[prov.lunmap]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: flushing Netapp Lun map #{@resource[:lunmap]}.")

    # Are we updating or destroying?
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: required resource state = #{@property_hash[:ensure]}")
    if @property_hash[:ensure] == :absent
      Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Ensure is absent. Destroying...")

      # Split the lunmap to path and lun-id
      path, lun_id = @resource[:lunmap].split(':')
      Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Unmapping lun id #{lun_id} on path #{path}.")

      # Deleting the lun
      result = lun_unmap('path', path, 'initiator-group', @resource[:initiatorgroup])

      Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Lun #{path} has been unmapped from initiatorgroup #{@resource[:initiatorgroup]}. ")
      return true
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: creating Netapp Lun #{@resource[:lunmap]}.")

    # Split the lunmap to path and lun-id
    path, lun_id = @resource[:lunmap].split(':')
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Mapping lun id #{lun_id} on path #{path}.")

    # Map the lun
    result = lun_map('path', path, 'lun-id', lun_id, 'initiator-group', @resource[:initiatorgroup])

    # Lun mapped successfully
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: Lun #{@resource[:lunmap]} created successfully.")
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: destroying Netapp Lun #{@resource[:lunmap]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_lun_map.cmode: checking existance of Netapp Lun #{@resource[:lunmap]}.")
    @property_hash[:ensure] == :present
  end

end
