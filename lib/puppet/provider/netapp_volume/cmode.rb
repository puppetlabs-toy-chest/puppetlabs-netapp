require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_volume).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Volume creation, modification and deletion. [Family: vserver]"

  confine :feature => :posix

  netapp_commands :vollist        => {:api => 'volume-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :optslist       => 'volume-options-list-info'
  netapp_commands :volsizeset     => 'volume-size'
  netapp_commands :volmodify      => 'volume-modify-iter'
  netapp_commands :snapresset     => 'snapshot-set-reserve'
  netapp_commands :autosizeset    => 'volume-autosize-set'
  netapp_commands :voloptset      => 'volume-set-option'
  netapp_commands :volcreate      => 'volume-create'
  netapp_commands :volrestrict    => 'volume-restrict'
  netapp_commands :voloffline     => 'volume-offline'
  netapp_commands :volonline      => 'volume-online'
  netapp_commands :voldestroy     => 'volume-destroy'
  netapp_commands :volmount       => 'volume-mount'
  netapp_commands :volunmount     => 'volume-unmount'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode: got to self.instances for cMode provider.")
    volumes = []

    # Get init-size details
    volume_info = get_volinfo

    # Itterate through each 'volume-info' block
    volume_info.each do |volume|
      vol_name = volume[:name]
      # Construct required information
      volume_hash = { :name => vol_name,
                      :ensure => :present }

      # Initsize
      # Need to convert from bytes to biggest possible unit
      vol_size_bytes = volume[:size_bytes]
      vol_size_mb = vol_size_bytes / 1024 / 1024
      if vol_size_mb % 1024 == 0
        vol_size_gb = vol_size_mb / 1024
        if vol_size_gb % 1024 == 0
          vol_size_tb = vol_size_gb / 1024
          vol_size = vol_size_tb.to_s + "t"
        else
          vol_size = vol_size_gb.to_s + "g"
        end
      else
        vol_size = vol_size_mb.to_s + "m"
      end
      volume_hash[:initsize] = vol_size

      # Get volume snapreserve
      volume_hash[:snapreserve] = volume[:snap_reserve]

      # Get autosize setting
      volume_hash[:autosize] = volume[:auto_size]

      # Get volume state
      volume_hash[:state] = volume[:state]

      # Get export policy
      volume_hash[:exportpolicy] = volume[:exportpolicy]

      # Get junction path
      volume_hash[:junctionpath] = volume[:junctionpath]

      # Get snapshot policy
      volume_hash[:snapshot_policy] = volume[:snapshot_policy]

      if ! transport.get_vserver.empty?
        # Get volume options, only if volume is online.
        if (volume[:state] == "online")
          # Get volume options
          volume_hash[:options] = self.get_options(vol_name)
        end
      else
        Puppet.debug("Puppet::Provider::Netapp_volume.cmode self.instances: Not a vserver; skipping options")
      end

      # Create the instance and add to volumes array.
      volumes << new(volume_hash)
    end
    volumes
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
      # Check if volume is online.
      self.class.get_volinfo.each do |volume|
        next unless volume[:name] == resource[:name]
        voldestroy('name', resource[:name])
      end
    end

    @property_hash.clear
  end

  #
  ## Getters
  #

  # Volume info getter
  def self.get_volinfo
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: getting volume info for all volumes.")

    # Pull back current volume-size.
    result = vollist("verbose", "true") || []
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: Pulling back volumes array.")
    volumes = Array.new

    # Itterate through the volume-info blocks
    result.each do |volume|
      #Puppet.debug("Volume = #{volume.inspect}")

      # Pull out relevant info blocks
      vol_id_info = volume.child_get("volume-id-attributes")
      vol_space_info = volume.child_get("volume-space-attributes")
      vol_state_info = volume.child_get("volume-state-attributes")
      vol_autosize_info = volume.child_get("volume-autosize-attributes")
      vol_snapshot_info = volume.child_get("volume-snapshot-attributes")

      # Get name
      vol_name = vol_id_info.child_get_string("name")
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: Processing volume #{vol_name}.")

      vol_snapshot_policy = vol_snapshot_info.child_get_string("snapshot-policy")
      vol_size_bytes = vol_space_info.child_get_int("size")
      vol_state = vol_state_info.child_get_string("state")
      vol_root = vol_state_info.child_get_string("is-vserver-root")
      vol_snap_reserve = vol_space_info.child_get_int("percentage-snapshot-reserve")
      #vol_raid_status = volume.child_get_string("raid-status")
      if vol_export_attributes = volume.child_get("volume-export-attributes")
        vol_export_policy = vol_export_attributes.child_get_string("policy")
      end
      # Get Auto size settings.
      if vol_state != 'offline'
        vol_auto_size = vol_autosize_info.child_get_string("mode")
      end

      # Get junction path
      if jp = vol_id_info.child_get("junction-path")
        vol_junction_path = jp.content
      else
        vol_junction_path = false
      end
      # Check if autosize is set
      #if (vol_auto_size =~ /^grow/)
      #  Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: vol_auto_size is not set to 'off'. Getting 'is-enabled' status.")
      #  vol_auto_size = vol_auto_size.child_get("autosize-info")
      #  vol_auto_size = vol_auto_size.child_get_string("is-enabled").to_sym
      #elsif (vol_state != "online")
      #  Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: volume is not online. Returning true.")
      #  vol_auto_size = :true
      #elsif ( vol_raid_status.include? "snapmirrored" )
      #  Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: volume is snapmirrored. Returning true.")
      #  vol_auto_size = :true
      #else
      #  Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: vol_auto_size is null and volume is online.")
      #  vol_auto_size = :false
      #end

      Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_volinfo: Vol_name = #{vol_name}, vol_size_bytes = #{vol_size_bytes}, vol_state = #{vol_state}, vol_snap_reserve = #{vol_snap_reserve} vol_export_policy = #{vol_export_policy}, vol_auto_size = #{vol_auto_size}.")

      # Construct hash
      vol_info = {
        :name            => vol_name,
        :size_bytes      => vol_size_bytes,
        :state           => vol_state,
        :snap_reserve    => vol_snap_reserve,
        :snapshot_policy => vol_snapshot_policy,
        :exportpolicy    => vol_export_policy,
        :auto_size       => vol_auto_size,
        :junctionpath    => vol_junction_path,
        :vserver_root    => vol_root,
      }

      Puppet.debug("Vol_info looks like: #{vol_info.inspect}")
      # Add to array
      volumes << vol_info

    end
    Puppet.debug("Processed all volumes. Returning array.")
    # Return volumes array
    volumes
  end

  # Volume options getter
  def self.get_options(name)
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode get_options: getting current volume options for Volume #{name}")

    # Create hash for current_options
    current_options = {}

    # Pull list of volume-options
    output = optslist("volume", name)
    # Get the options list
    options = output.child_get("options")

    # Get volume-option-info children
    volume_options = options.children_get()
    volume_options.each do |volume_option|
      # Extract values to put into options hash
      name = volume_option.child_get_string("name")
      value = volume_option.child_get_string("value")
      # Construct hash of current options and corresponding value.
      current_options[name] = value
    end

    # Return current_options
    current_options
  end

  #
  ## Setters
  #

  # Volume junction-path setter
  def junctionpath=(value)
    if ! value
      result = volunmount("volume-name", @resource[:name])
    else
      result = volmount("volume-name", @resource[:name], "junction-path", value)
    end
    return true
  end

  # Volume initsize setter
  def initsize=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode initsize=: setting volume size for Volume #{@resource[:name]}")

    # Query Netapp to update volume size.
    volsizeset("volume", @resource[:name], "new-size", @resource[:initsize])
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode initsize=: Volume size set succesfully for volume #{@resource[:name]}.")
    # Trigger and autosize run if required.
    if @resource[:autosize] == :true
      self.send('autosize=', resource['autosize'.to_sym]) if resource['autosize'.to_sym]
    end
    return true
  end

  # Snap reserve setter
  def snapreserve=(value)
    snapresset("volume", @resource[:name], "percentage", @resource[:snapreserve])
  end

  # autosize setter
  def autosize=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: setting auto-increment for Volume #{@resource[:name]} to #{@resource[:autosize]}")

    # Enabling or disabling autosize
    if @resource[:autosize] != :off
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Enabling autosize.")

      # Need to work out a sensible auto-increment size
      # Max growth of 20%, increment of 5%
      size, unit = (@resource[:initsize] || self.initsize).match(/^(\d+)([A-Z])$/i).captures

      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Volume size = #{size}, unit = #{unit}.")

      # Need to convert size into MB...
      if unit == 'g'
        size = size.to_i * 1024
      elsif unit == 't'
        size = size.to_i * 1024 * 1024
      end
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Volume size in m = #{size}.")

      # Set max-size
      maxsize = (size.to_i*1.2).to_i
      incrsize = (size.to_i*0.05).to_i
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Maxsize = #{maxsize}, incrsize = #{incrsize}.")

      # Query Netapp to set autosize status.
      result = autosizeset("volume", @resource[:name], "mode", @resource[:autosize], "maximum-size", maxsize.to_s + "m", "increment-size", incrsize.to_s + "m")
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Auto-increment set succesfully for volume #{@resource[:name]}.")
    else
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Disabling autosize.")
      # Query Netapp to set autosize status.
      result = autosizeset("volume", @resource[:name], "mode", @resource[:autosize])
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode autosize=: Auto-increment disabled succesfully for volume #{@resource[:name]}.")
    end
    return true
  end

  # Volume options setter.
  def options=(opts_array)
    opts = opts_array.first
    opts.each do |setting,value|
      # Itterate through each options pair.
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode options=: Setting = #{setting}, Value = #{value}")
      # Call webservice to set volume option.
      voloptset("volume", @resource[:name], "option-name", setting, "option-value", value)
      Puppet.debug("Puppet::Provider::Netapp_volume.cmode  options=: Volume Option #{setting} set against Volume #{@resource[:name]}.")
    end
    # All volume options set successfully.
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode options=: Volume Options set against Volume #{@resource[:name]}.")
    return true

  end

  # Volume state setter.
  def state=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode state=: Got to state setter.")

    # Get the required_state value
    required_state = value
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode state=: Required state = #{required_state}.")

    # Handle the required_state value
    if (required_state == :online)
      Puppet.debug("Onlining volume #{@resource[:name]}.")
      # Online volume
      result = volonline("name", @resource[:name])
    elsif (required_state == :offline)
      Puppet.debug("Offlining volume #{@resource[:name]}.")
      # Offline volume
      result = voloffline("name", @resource[:name])
    elsif (required_state == :restricted)
      Puppet.debug("Restricting volume #{@resource[:name]}.")
      # Restrict volume
      result = volrestrict("name", @resource[:name])
    end

    Puppet.debug("Puppet::Provider::Netapp_volume.cmode state=: #{@resource[:name]} status set to #{required_state}.")
    return true
  end

  # Export policy setter
  def exportpolicy=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode exportpolicy=: setting export policy value for Volume #{@resource[:name]} to #{@resource[:exportpolicy].inspect}")

    # Build up the attributes to set
    volume_export_attributes = NaElement.new('volume-export-attributes')
    volume_export_attributes.child_add_string('policy', @resource[:exportpolicy])
    volume_attributes = NaElement.new('volume-attributes')
    volume_attributes.child_add(volume_export_attributes)

    # Build up the query
    volume_id_attributes = NaElement.new("volume-id-attributes")
    volume_id_attributes.child_add_string("name", @resource[:name])
    volume_query = NaElement.new('volume-attributes')
    volume_query.child_add(volume_id_attributes)

    # I don't know why I can't just pass the attributes and query directly, so
    # I have to make an invoke_elem NaElement call instead
    #result = volmodify("attributes", volume_attributes, "query", volume_query)
    volume_modify = NaElement.new('volume-modify-iter')
    volume_set = NaElement.new('attributes')
    volume_set.child_add(volume_attributes)
    volume_modify.child_add(volume_set)
    volume_get = NaElement.new('query')
    volume_get.child_add(volume_query)
    volume_modify.child_add(volume_get)
    volmodify(volume_modify)
  end

 def snapshot_policy=(value)
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode snapshot_policy=: setting snapshot policy value for Volume #{@resource[:name]} to #{@resource[:snapshot_policy].inspect}")

    # Build up the attributes to set
    volume_snapshot_attributes = NaElement.new('volume-snapshot-attributes')
    volume_snapshot_attributes.child_add_string('snapshot-policy', @resource[:snapshot_policy])
    volume_attributes = NaElement.new('volume-attributes')
    volume_attributes.child_add(volume_snapshot_attributes)

    # Build up the query
    volume_id_attributes = NaElement.new("volume-id-attributes")
    volume_id_attributes.child_add_string("name", @resource[:name])
    volume_query = NaElement.new('volume-attributes')
    volume_query.child_add(volume_id_attributes)

    volume_modify = NaElement.new('volume-modify-iter')
    volume_set = NaElement.new('attributes')
    volume_set.child_add(volume_attributes)
    volume_modify.child_add(volume_set)
    volume_get = NaElement.new('query')
    volume_get.child_add(volume_query)
    volume_modify.child_add(volume_get)

    volmodify(volume_modify)
  end
  # Volume create.
  def create
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode: creating Netapp Volume #{resource[:name]} of initial size #{resource[:initsize]} in Aggregate #{resource[:aggregate]} using space reserve of #{resource[:spaceres]}, with a state of #{resource[:state]}.")
    # Call webservice to create volume.
    arguments =  ["volume", resource[:name]]
    arguments += ["containing-aggr-name", resource[:aggregate]]
    arguments += ["size", resource[:initsize]] if resource[:initsize]
    arguments += ["language-code", resource[:languagecode]] if resource[:languagecode]
    arguments += ["space-reserve", resource[:spaceres]] if resource[:spaceres]
    arguments += ["volume-type", resource[:volume_type]] if resource[:volume_type]
    arguments += ["group-id", resource[:group_id]] if resource[:group_id]
    arguments += ["user-id", resource[:user_id]] if resource[:user_id]
    arguments += ["unix-permissions", resource[:unix_permissions]] if resource[:unix_permissions]
    volcreate(*arguments)

    # Update other attributes after resource creation.
    methods = [
      'autosize',
      'exportpolicy',
      'snapshot_policy',
      'junctionpath',
      'options',
      'snapreserve',
    ]

    methods.each do |method|
      self.send("#{method}=", resource[method.to_sym]) if resource[method.to_sym]
    end

    # Handle volume state seperately
    unless (@resource[:state] == :online)
      self.send("state=", resource["state".to_sym]) if resource["state".to_sym]
    end

    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_volume.cmode: destroying Netapp Volume #{@resource[:name]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
