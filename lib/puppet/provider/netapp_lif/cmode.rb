require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_lif).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Logical Interface (LIF) export rule creation, modification and deletion."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :liflist    => {:api => 'net-interface-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :lifcreate  => 'net-interface-create'
  netapp_commands :lifdel     => 'net-interface-delete'
  netapp_commands :lifmodify  => 'net-interface-modify'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Got to self.instances.")
    lifs = []

    #Get a list of all LIF's
    results = liflist() || []

    # Itterate through the results
    results.each do |lif|
      lif_name = lif.child_get_string("interface-name")
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Processing lif #{lif_name}.")

      # Construct initial hash for lif
      lif_hash = {
        :name   => lif_name,
        :ensure => :present
      }

      # Pull out required info
      required_fields = %w(address administrative-status comment dns-domain-name failover-group failover-policy
      firewall-policy home-node home-port is-auto-revert netmask netmask-length routing-group-name
      use-failover-group)

      required_fields.each do |field|
        Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Getting value for #{field}.")

        value = lif.child_get_string(field)
        field = field.gsub('-','').to_sym
        Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Adding #{field} = #{value} to hash.") unless value.nil?

        lif_hash[field] = value unless value.nil?
      end

      # Process data-protocols array
      data_protocols = []
      dp_element = lif.child_get('data-protocols')
      if dp_element
        dp_element.children_get().each do |lif_dp|
          data_protocols << lif_dp.content()
        end
        lif_hash[:dataprotocols] = data_protocols
      end

      # Create the instance and add to lifs array
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Creating instance for #{lif_name}\n Contents = #{lif_hash.inspect}.")
      lifs << new(lif_hash)
    end

    # Return the final lifs array
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Returning lifs array.")
    lifs
  end


  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end


  def flush
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: flushing Netapp LIF #{@resource[:interfacename]}.")

    # Are we updating or destroying?
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: required resource state = #{@property_hash[:ensure]}")
    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Ensure is absent. Destroying...")

      # Deleting the lif
      lifdel('interface-name', @resource[:interfacename], 'vserver', @resource[:vserver])

      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: LIF #{@resource[:interfacename]} has been deleted successfully. ")
      return true

    when :present
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Ensure is present. Modifying...")

      # Construct a net-interface-modify request
      lif_modify = NaElement.new('net-interface-modify')

      # Add values to it
      modify_fields = %w(interface-name address administrative-status comment dns-domain-name failover-group failover-policy
        firewall-policy home-node home-port is-auto-revert netmask netmask-length routing-group-name
        use-failover-group vserver)

      modify_fields.each do |field|
        Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Processing field #{field}.")

        # Pull value from resource hash, stripping '-' from field.
        value = @resource[field.gsub('-','').to_sym]
        lif_modify.child_add_string(field, value) unless value.nil?
        Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Added #{field} with value #{value}. ") unless value.nil?
      end

      # Create the lif
      result = lifmodify(lif_modify)

      # Passed above, therefore must of worked.
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: lif #{@resource[:interfacename]} modified successfully. \n")
      return true
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: creating Netapp LIF #{@resource[:interfacename]}.")

    # Construct a net-interface-create request
    lif_create = NaElement.new('net-interface-create')

    # Add values to it
    create_fields = %w(interface-name address administrative-status comment dns-domain-name failover-group failover-policy
      firewall-policy home-node home-port is-auto-revert netmask netmask-length routing-group-name
      role use-failover-group vserver)

    create_fields.each do |field|
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Processing field #{field}.")

      # Pull value from resource hash, stripping '-' from field.
      value = @resource[field.gsub('-','').to_sym]
      lif_create.child_add_string(field, value) unless value.nil?
      Puppet.debug("Puppet::Provider::Netapp_lif.cmode: Added #{field} with value #{value}. ") unless value.nil?
    end

    # Add required dataprotocols
    dataprotocols_element = NaElement.new('data-protocols')
    Array(@resource[:dataprotocols]).each do |dp|
      dataprotocols_element.child_add_string('data-protocol', dp)
    end unless @resource[:dataprotocols].nil?
    lif_create.child_add(dataprotocols_element)

    # Create the lif
    result = lifcreate(lif_create)

    # LIF created successfully
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: LIF #{@resource[:interfacename]} created successfully.")
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: destroying Netapp LIF #{@resource[:interfacename]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_lif.cmode: checking existance of Netapp LIF rule #{@resource[:interfacename]}.")
    @property_hash[:ensure] == :present
  end

end
