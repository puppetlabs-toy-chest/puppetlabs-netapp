require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_lun).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Lun creation, modification and deletion. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :lunlist    => {:api => 'lun-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :luncreate  => 'lun-create-by-size'
  netapp_commands :lundestroy => 'lun-destroy'
  netapp_commands :lunresize  => 'lun-resize'
  netapp_commands :lunonline  => 'lun-online'
  netapp_commands :lunoffline => 'lun-offline'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Got to self.instances.")
    luns = []

    #Get a list of all Lun's
    results = lunlist() || []

    # Itterate through the results
    results.each do |lun|
      lun_path = lun.child_get_string('path')
      Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Processing lun #{lun_path}.")

      # Construct initial hash for lun
      lun_hash = {
        :name   => lun_path,
        :ensure => :present
      }

      # Grab additional elements
      # Lun state - Need to map true/false to online/offline
      lun_state = lun.child_get_string('online')
      if lun_state == 'true'
        lun_hash[:state] = 'online'
      else
        lun_hash[:state] = 'offline'
      end

      # Get size
      lun_hash[:size] = lun.child_get_string('size')

      # Create the instance and add to luns array
      Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Creating instance for #{lun_path}\n Contents = #{lun_hash.inspect}.")
      luns << new(lun_hash)
    end

    # Return the final luns array
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Returning luns array.")
    luns
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.path = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end


  def flush
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: flushing Netapp Lun #{@resource[:path]}.")

    # Are we updating or destroying?
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: required resource state = #{@property_hash[:ensure]}")
    if @property_hash[:ensure] == :absent
      Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Ensure is absent. Destroying...")

      # Deleting the lun
      lundestroy('path', @resource[:path])

      Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Lun #{@resource[:path]} has been destroyed successfully. ")
      return true
    end
  end

  # Set lun size
  def size=(value)
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode size=: Setting lun size for #{@resource[:path]} to #{@resource[:size]}.")

    force
    if @resource[:force] == nil
      force = false
    else
      force = @resource[:force]
    end
    # Resize the volume
    result = lunresize('force', force, 'path', @resource[:path], 'size', @resource[:size])
    if result.results_status() != "failed"
      Puppet.debug("Puppet::Provider::Netapp_lun.cmode size=: Lun has been resized.")
      return true
    end
  end

  # Set lun state
  def state=(value)
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode state=: Setting lun state for #{@resource[:path]} to #{@resource[:state]}.")

    case @resource[:state]
    when :online
      Puppet.debug("Puppet::Provider::Netapp_lun.cmode state=: Onlineing lun.")
      result = lunonline('path', @resource[:path])

      Puppet.debug("Puppet::Provider::Netapp_lun.cmode state=: Lun has been onlined.")
      return true

    when :offline
      Puppet.debug("Puppet::Provider::Netapp_lun.cmode state=: Offlining lun.")
      result = lunoffline('path', @resource[:path])

      Puppet.debug("Puppet::Provider::Netapp_lun.cmode state=: Lun has been offlined.")
      return true
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: creating Netapp Lun #{@resource[:path]}.")

    # Lun create args
    luncreate_args = []
    luncreate_args << 'path' << @resource[:path]
    luncreate_args << 'size' << @resource[:size]
    luncreate_args << 'class' << @resource[:lunclass]
    luncreate_args << 'ostype' << @resource[:ostype]
    luncreate_args << 'space-reservation-enabled' << @resource[:spaceresenabled]

    # Optional fields
    luncreate_args << 'prefix-size' << @resource[:prefixsize] unless @resource[:prefixsize].nil?
    luncreate_args << 'qos-policy-group' << @resource[:qospolicygroup] unless @resource[:qospolicygroup].nil?

    # Create the lun
    result = luncreate(*luncreate_args)

    # Lun created successfully
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: Lun #{@resource[:path]} created successfully.")
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: destroying Netapp Lun #{@resource[:path]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_lun.cmode: checking existance of Netapp Lun #{@resource[:path]}.")
    @property_hash[:ensure] == :present
  end

end
