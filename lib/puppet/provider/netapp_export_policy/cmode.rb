require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_export_policy).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp CMode export policy creation and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix
  
  netapp_commands :eplist => {:api => 'export-policy-get-iter', :iter => true, :result_element => 'attributes-list' }
  netapp_commands :epadd  => 'export-policy-create'
  netapp_commands :epdel  => 'export-policy-destroy'
  
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: got to self.instances.")
    export_policies = []

    # Get a list of all export policies 
    result = eplist

    # Itterate through each 'export-policy-info' block.
    result.each do |policy|
      name = policy.child_get_string("policy-name")
      Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode.prefetch: Got export policy #{name}. \n")
      
      # Construct an export policy hash for policy
      export_policy = { :name => name,
                        :ensure => :present }
      
      # Create the instance and add to export_policies array.
      Puppet.debug("Creating instance for #{name}. \n")
      export_policies << new(export_policy)
    end
  
    # Return the final export_policies array. 
    Puppet.debug("Returning export_policiess array. ")
    export_policies
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: Got to flush for resource #{@resource[:name]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: Ensure is absent.")

      # Remove the export policy
      result = epdel('policy-name', @resource[:name])
      
      Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: export policy #{@resource[:name]} destroyed successfully. \n")
      return true
    
    end #EOC
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: creating Netapp export policy #{@resource[:name]}.")

    # Create the export policy
    result = epadd('policy-name', @resource[:name])

    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: export policy #{@resource[:name]} created successfully.")
    return true
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: destroying Netapp export policy #{@resource[:name]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_export_policy.cmode: checking existance of Netapp export policy #{@resource[:name]}.")
    @property_hash[:ensure] == :present
  end

  
end
