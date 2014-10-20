require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_aggregate).provide(:cmode, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Cluster aggregate management."

  confine :feature => :posix
  defaultfor :feature => :posix

  # Restrict to cMode
  confine :true => begin
    a = Puppet::Node::Facts.indirection
    a.terminus_class = :network_device
    a.find(Puppet::Indirector::Request.new(:facts, :find, "clustered", nil))
  rescue
    :false
  end

  netapp_commands :aggrget     => {:api => 'aggr-get-iter', :iter => true, :result_element =>'attributes-list'} 
  netapp_commands :aggrcreate  => 'aggr-create'
  netapp_commands :aggradd     => 'aggr-add'
  netapp_commands :aggrmod     => 'aggr-modify'
  netapp_commands :aggrdestroy => 'aggr-destroy'
  netapp_commands :aggronline  => 'aggr-online'
  netapp_commands :aggroffline => 'aggr-offline'
  
  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode self.instances: Got to self.instances.")
    
    aggregates = []
    
    # Get the aggregates
    results = aggrget()
    
    results.each do |aggregate|
      # Pull out relevant fields
      aggregate_name = aggregate.child_get_string('aggregate-name')
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode self.instances: Getting aggregate info for #{aggregate_name}.")
      
      # Construct the aggr_info hash
      aggr_info = {
        :name => aggregate_name,
        :ensure => :present
      }

      # Start to add values
      # Aggregate state 
      aggr_info[:state] = aggregate.child_get('aggr-raid-attributes').child_get_string('state')
      # Aggregate blocktype. 
      aggr_info[:blocktype] = aggregate.child_get('aggr-fs-attributes').child_get_string('block-type') 

      # Get current diskcount
      aggr_info[:diskcount] = aggregate.child_get('aggr-raid-attributes').child_get_string('disk-count')
      
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode self.instances: aggr_info = #{aggr_info}.")
      aggregates << new(aggr_info)
    end
    
    aggregates
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cMode: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end
  
  def flush
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cMode flush: Got to flush for resource #{@resource[:name]}.")

    # Are we updating or destroying? 
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: required resource state = #{@property_hash[:ensure]}")

    # Can't modify an aggregate if it's creating, so early out. 
    if @property_hash[:state] == 'creating'
        Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Aggregate is creating, can't modify...")
      return true
    end

    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Ensure is absent. Destroying...")

      # Offline the aggregate
      result = aggroffline('aggregate', @resource[:name])
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Aggregate #{@resource[:name]} has been offlined. Destroying...")

      # Destroy the aggregate
      result = aggrdestroy('aggregate', @resource[:name])
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Aggregate #{@resource[:name]} has been destroyed.")
      return true

    when :present
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Ensure is present. Modifying...")

      # Add disks to the existing aggregate
      result = aggradd('aggregate', @resource[:name], 'disk-count', @resource[:diskcount])

      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Aggregate #{@resource[:name]} has been modified.")
      return true

    end
  end

  # Aggregate state setter
  def state=(value)
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode state: Setting aggregate #{@resource[:name]} to state #{@resource[:state]}.")

    # Set the aggregate state
    case @resource[:state]
    when :online
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode state=: Bringing aggregate #{@resource[:name]} online.")

      result = aggronline('aggregate', @resource[:name])

      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode state=: Aggregate online.")
      return true
    when :offline
      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode state=: Taking aggregate #{@resource[:name]} offline.")

      result = aggroffline('aggregate', @resource[:name])

      Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode state=: Aggregate offline.")
      return true
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode create: Creating aggregate #{@resource[:name]}")

    # Create a aggr-create NaElement
    aggr_create = NaElement.new('aggr-create')

    # Start adding values
    aggr_create.child_add_string('aggregate', @resource[:name])
    aggr_create.child_add_string('block-type', @resource[:blocktype])
    aggr_create.child_add_string('checksum-style', @resource[:checksumstyle])
    aggr_create.child_add_string('disk-count', @resource[:diskcount])
    aggr_create.child_add_string('disk-size-with-unit', @resource[:disksize]) unless @resource[:disksize].nil?
    aggr_create.child_add_string('disk-type', @resource[:disktype]) unless @resource[:disktype].nil?
    aggr_create.child_add_string('is-mirrored', @resource[:ismirrored])
    aggr_create.child_add_string('raid-size', @resource[:raidsize]) unless @resource[:raidsize].nil?
    aggr_create.child_add_string('raid-type', @resource[:raidtype])
    aggr_create.child_add_string('striping', @resource[:striping])

    # Add nodes object
    nodes = NaElement.new('nodes')
    @resource[:nodes].each do |node|
      node.child_add_string('node-name', node)
    end unless @resource[:nodes].nil?
    aggr_create.child_add(nodes)

    # Add the aggregate
    result = aggrcreate(aggr_create)

    # Passed above, so must have created aggregate successfully
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode create: Aggregate #{@resource[:name]} created successfully.")
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode: Destroying aggregate #{@resource[:name]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_aggregate.cmode exists?: checking existance of Netapp aggregate #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end

end
