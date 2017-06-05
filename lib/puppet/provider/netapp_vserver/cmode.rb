require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_vserver).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Vserver creation, modification and deletion. [Family: cluster, vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :vserverlist  => {:api => 'vserver-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :vserveradd   => 'vserver-create'
  netapp_commands :vserverdel   => 'vserver-destroy'
  netapp_commands :vservermod   => 'vserver-modify-iter'
  netapp_commands :vserverstart => 'vserver-start'
  netapp_commands :vserverstop  => 'vserver-stop'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode: got to self.instances for cMode provider.")

    # Get vserver info
    results = vserverlist()
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode instances: processing vserver list")

    vservers = []

    # Itterate through the vserver-info blocks
    results.each do |vserver|

      # Pull out vserver name and type
      vserver_name = vserver.child_get_string("vserver-name")
      vserver_type = vserver.child_get_string("vserver-type")

      Puppet.debug("Vserver #{vserver_name} is a #{vserver_type} node type.")
      next unless vserver_type == 'data'

      # Pull out relevant info fields
      root_volume = vserver.child_get_string("root-volume")
      root_volume_aggregate = vserver.child_get_string("root-volume-aggregate")
      root_volume_sec_style = vserver.child_get_string("root-volume-security-style")
      comment = vserver.child_get_string("comment")
      ipspace = vserver.child_get_string("ipspace")
      language = vserver.child_get_string("language")
      state = munge_state(vserver.child_get_string("state"))
      is_repository = vserver.child_get_string("is-repository-vserver")

      # Name mapping switch
      namemappingswitch = []
      namemappingswitch_info = vserver.child_get("name-mapping-switch").children_get()
      namemappingswitch_info.each do |nmswitch|
        namemappingswitch << nmswitch.content()
      end unless namemappingswitch_info.nil?
      # Name server switch
      nameserverswitch = []
      nameserverswitch_info = vserver.child_get("name-server-switch").children_get()
      nameserverswitch_info.each do |nsswitch|
        nameserverswitch << nsswitch.content()
      end unless nameserverswitch_info.nil?

      # Policies
      quota_policy = vserver.child_get_string("quota-policy")
      snapshot_policy = vserver.child_get_string("snapshot-policy")

      # Aggregates
      aggregates = []
      aggregates_info = vserver.child_get("aggr-list")
      aggregates_info.children_get().each do |aggregate|
        aggregates << aggregate.content()
      end unless aggregates_info.nil?

      # Protocols
      protocols = []
      protocols_info = vserver.child_get("allowed-protocols").children_get()
      protocols_info.each do |protocol|
        protocols << protocol.content()
      end unless protocols_info.nil?

      Puppet.debug("Puppet::Provider::Netapp_vserver.cmode instances: Vserver_name = #{vserver_name}.")

      # Construct hash
      vserver_info = {
        :name              => vserver_name,
        :ensure            => :present,
        :state             => state,
        :rootvol           => root_volume,
        :rootvolaggr       => root_volume_aggregate,
        :rootvolsecstyle   => root_volume_sec_style,
        :comment           => comment,
        :ipspace           => ipspace,
        :language          => language,
        :namemappingswitch => namemappingswitch,
        :nameserverswitch  => nameserverswitch,
        :quotapolicy       => quota_policy,
        :snapshotpolicy    => snapshot_policy,
        :aggregatelist     => aggregates,
        :allowedprotos     => protocols,
        :is_repository     => is_repository,
      }

      Puppet.debug("Puppet::Provider::Netapp_vserver.cmode instances: vserver_info looks like: #{vserver_info.inspect}")

      # Add to array
      vservers << new(vserver_info)

    end
    Puppet.debug("Processed all vservers. Returning array.")
    # Return volumes array
    vservers

  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode flush: Got to flush for resource #{@resource[:name]}.")

    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_vserver.cmode flush: Required ensure = absent. Destroying vserver #{@resource[:name]}.")

      # Destroy the vserver.
      result = vserverdel('vserver-name', @resource[:name])
      Puppet.debug("Puppet::Provider::Netapp_vserver.cmode flush: Vserver destroyed successfully.")
      return true

    when :present
      Puppet.debug("Puppet::Provider::Netapp_vserver.cmode flush: Required ensure = present. Modifying vserver #{@resource[:name]}.")

      # Create a vserver-modify attributes object
      vserver_attributes = NaElement.new('vserver-info')
      vserver_query = NaElement.new('vserver-info')

      # Create a vserver-modify query object
      vserver_query.child_add_string('vserver-name', @resource[:name])

      # Build up the modify object
      vserver_attributes.child_add_string('vserver-name', @resource[:name])
      vserver_attributes.child_add_string('comment', @resource[:comment]) if @resource[:comment]
      vserver_attributes.child_add_string('language', @resource[:language])
      vserver_attributes.child_add_string('quota-policy', @resource[:quotapolicy]) if @resource[:quotapolicy]
      vserver_attributes.child_add_string('snapshot-policy', @resource[:snapshotpolicy]) if @resource[:snapshotpolicy]
      vserver_attributes.child_add_string('max-volumes', @resource[:maxvolumes]) if @resource[:maxvolumes]

      # Process namemappingswitch array values
      if !@resource[:namemappingswitch].nil?
        nms_element = NaElement.new("name-mapping-switch")

        Array(@resource[:namemappingswitch]).each do |value|
          nms_element.child_add_string("nmswitch", value)
        end
        vserver_attributes.child_add(nms_element)
      end

      # Process nameserverswitch array values
      if !@resource[:nameserverswitch].nil?
        nss_element = NaElement.new("name-server-switch")

        Array(@resource[:nameserverswitch]).each do |value|
          nss_element.child_add_string("nsswitch", value)
        end
        vserver_attributes.child_add(nss_element)
      end

      # Process aggregatelist array values
      if !@resource[:aggregatelist].nil?
        aggrlist_element = NaElement.new("aggr-list")

        Array(@resource[:aggregatelist]).each do |value|
          aggrlist_element.child_add_string("aggr-name", value)
        end
        vserver_attributes.child_add(aggrlist_element)
      end

      # Process allowedprotos array values
      if !@resource[:allowedprotos].nil?
        allowedprotos_element = NaElement.new('allowed-protocols')

        Array(@resource[:allowedprotos]).each do |value|
          allowedprotos_element.child_add_string('protocol', value)
        end
        vserver_attributes.child_add(allowedprotos_element)
      end

      # Modify the vserver
      vserver_modify = NaElement.new('vserver-modify-iter')
      vserver_set = NaElement.new('attributes')
      vserver_set.child_add(vserver_attributes)
      vserver_modify.child_add(vserver_set)
      vserver_get = NaElement.new('query')
      vserver_get.child_add(vserver_query)
      vserver_modify.child_add(vserver_get)
      vservermod(vserver_modify)
    end

    #@property_hash.clear
  end

  #
  ## Getters
  #

  #
  ## Setters
  #
  def is_repository=(value)
    raise ArgumentError, "is_repository cannot be changed after creation"
  end

  # VServer state setter.
  def state=(value)
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode state=: Got to state setter.")

    # Get the required_state value
    required_state = value
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode state=: Required state = #{required_state}, class = #{required_state.class}.")

    # Handle the required_state value
    if (required_state == :stopped)
      Puppet.debug("Stopping vserver #{@resource[:name]}.")
      # Stop vserver
      result = vserverstop("vserver-name", @resource[:name])
    elsif (required_state == :running)
      Puppet.debug("Starting vserver #{@resource[:name]}.")
      # Start vserver
      result = vserverstart("vserver-name", @resource[:name])
    end

    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode state=: #{@resource[:name]} vserver state set to #{required_state}.")
    return true
  end

  # vserver create.
  def create
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode: creating Netapp Vserver #{@resource[:name]} with a state of #{@resource[:state]}.")

    # Compile vservercreate_opts
    vserver_create = NaElement.new("vserver-create")
    vserver_create.child_add_string("vserver-name", @resource[:name])
    vserver_create.child_add_string("comment", @resource[:comment]) if @resource[:comment]
    vserver_create.child_add_string("ipspace", @resource[:ipspace]) if @resource[:ipspace]
    vserver_create.child_add_string("language", @resource[:language])
    vserver_create.child_add_string("is-repository-vserver", @resource[:is_repository]) if @resource[:is_repository]
    vserver_create.child_add_string("quota-policy", @resource[:quotapolicy]) if @resource[:quotapolicy]
    vserver_create.child_add_string("root-volume", @resource[:rootvol])
    vserver_create.child_add_string("root-volume-aggregate", @resource[:rootvolaggr])
    vserver_create.child_add_string("root-volume-security-style", @resource[:rootvolsecstyle])
    vserver_create.child_add_string("snapshot-policy", @resource[:snapshotpolicy]) if @resource[:snapshotpolicy]

    # Process namemappingswitch array values
    if !@resource[:namemappingswitch].nil?
      nms_element = NaElement.new("name-mapping-switch")

      Array(@resource[:namemappingswitch]).each do |value|
        nms_element.child_add_string("nmswitch", value)
      end
      vserver_create.child_add(nms_element)
    end

    # Process nameserverswitch array values
    if !@resource[:nameserverswitch].nil?
      nss_element = NaElement.new("name-server-switch")

      Array(@resource[:nameserverswitch]).each do |value|
        nss_element.child_add_string("nsswitch", value)
      end
      vserver_create.child_add(nss_element)
    end

    # # Process aggregatelist array values
    # if !@resource[:aggregatelist].nil?
    #   aggrlist_element = NaElement.new("aggr-list")

    #   Array(@resource[:aggregatelist]).each do |value|
    #     aggrlist_element.child_add_string("aggr-name", value)
    #   end
    #   vserver_create.child_add(aggrlist_element)
    # end

    Puppet.debug("Created vserver_create: #{vserver_create.inspect}")

    # Call webservice to create vserver.
    result = vserveradd(vserver_create)
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode: Vserver #{@resource[:name]} created successfully.")

    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode: destroying Netapp Vserver #{@resource[:name]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_vserver.cmode: checking existance of Netapp Vserver #{@resource[:name]}")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end

  def self.munge_state(value)
    case value
    when 'running'
      :running
    when 'starting'
      :running
    when 'stopped'
      :stopped
    when 'stopping'
      :stopped
    when 'initializing'
      :running
    else
      warning"This is an unknown state '#{value}', defaulting to :running"
      :running
    end
  end

end
