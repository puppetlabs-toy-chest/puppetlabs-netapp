require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_vserver_option).provide(:cmode, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Vserver option modification."

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

  netapp_commands :vsrvoptlist => {:api => 'options-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :vsrvoptset  => 'options-set'
  netapp_commands :vsrvoptmod  => 'options-modify-iter'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode: got to self.instances for cMode provider.")

    # Get vserver info
    results = vsrvoptlist()
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode instances: processing options")

    options = []

    # Itterate through the option-info blocks
    results.each do |option|

      # Pull out option name and value
      option_name = option.child_get_string("name")
      option_value = option.child_get_string("value")

      Puppet.debug("Option name #{option_name}, value #{option_value}.")

      # Construct hash
      option_info = {  
        :name   => option_name,
        :ensure => :present,
        :value  => option_value
      }

      Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode instances: option_info looks like: #{option_info.inspect}")

      # Add to array
      options << new(option_info)
    end

    Puppet.debug("Processed all options. Returning array.")
    # Return options array
    options

  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode flush: Got to flush for resource #{@resource[:name]}.")

    # Build up the attributes field
    option_attributes = NaElement.new('option-info')
    option_attributes.child_add_string('name', @resource[:name])
    option_attributes.child_add_string('value', @resource[:value])

    # Need a query object aswell
    option_query = NaElement.new('option-info')
    option_query.child_add_string('name', @resource[:name])

    # Execute it
    result = vsrvoptmod('attributes', option_attributes, 'query', option_query)

    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode flush: Option set successfully.")
    return true

  end

  #
  ## Getters
  #

  #
  ## Setters
  #

  # Volume create.
  def create
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode: Can't create vserver options.")

    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode: Can't destroy vserver options")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_vserver_option.cmode: checking existance of Netapp Vserver option #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end

end
