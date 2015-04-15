require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_export_rule).provide(:cmode, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp CMode export rule creation, modification and deletion."
  
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

  netapp_commands :elist   => {:api => 'export-rule-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :eadd    => 'export-rule-create' 
  netapp_commands :edel    => 'export-rule-destroy' 
  netapp_commands :emodify => 'export-rule-modify'
  
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: got to self.instances.")
    export_rules = []

    # Get a list of all nfs export rules
    result = elist

    # Itterate through each 'export-rule-info' block.
    result.each do |rule|
      policyname = rule.child_get_string("policy-name")
      ruleindex = rule.child_get_int("rule-index")
      name = "#{policyname}:#{ruleindex}"
      Puppet.debug("Puppet::Provider::Netapp_export.cmode.prefetch: Processing rule for export #{name}. \n")
      
      # Construct an export hash for rule
      export_rule = { :name => name,
                 :ensure => :present }
      
      # Add the anon UID if present.
      export_rule[:anonuid] = rule.child_get_string("anonymous-user-id") unless rule.child_get_string("anonymous-user-id").nil?
      # Add the client match string if present.
      export_rule[:clientmatch] = rule.child_get_string("client-match") unless rule.child_get_string("client-match").nil?
      
      # Export chown mode
      export_rule[:exportchownmode] = rule.child_get_string("export-chown-mode") unless rule.child_get_string("export-chown-mode").nil?

      # NTS Unix security ops
      export_rule[:ntfsunixsecops] = rule.child_get_string("export-ntfs-unix-security-ops") unless rule.child_get_string("export-ntfs-unix-security-ops").nil?

      # Add the allowdev and allowsetuid 
      export_rule[:allowdevenabled] = rule.child_get_string("is-allow-dev-is-enabled") unless rule.child_get_string("is-allow-dev-is-enabled").nil?
      export_rule[:allowsetuid] = rule.child_get_string("is-allow-set-uid-enabled") unless rule.child_get_string("is-allow-set-uid-enabled").nil?

      # Get an array of protocols
      protocols = []
      rule_protocols = rule.child_get('protocol').children_get()
      rule_protocols.each do |protocol|
        protocols << protocol.content()
      end
      # Add it to the export_rule hash
      export_rule[:protocol] = protocols

      # Get an array of read only security flavors 
      ro_security = []
      ro_rules = rule.child_get('ro-rule').children_get()
      ro_rules.each do |ro_rule|
        ro_security << ro_rule.content() 
      end
      # Add it to the export_rule hash
      export_rule[:rorule] = ro_security

      # Get an array of read write security flavors 
      rw_security = []
      rw_rules = rule.child_get('rw-rule').children_get()
      rw_rules.each do |rw_rule|
        rw_security << rw_rule.content()
      end
      # Add it to the export_rule hash
      export_rule[:rwrule] = rw_security

      # Get an array of super user security flavors 
      su_security = []
      su_rules = rule.child_get('super-user-security').children_get()
      su_rules.each do |su_rule|
        su_security << su_rule.content()
      end
      # Add it to the export_rule hash
      export_rule[:superusersecurity] = su_security

      # Create the instance and add to exports array.
      Puppet.debug("Creating instance for #{name}. \n")
      Puppet.debug("Export rule looks like: #{export_rule.inspect}")
      export_rules << new(export_rule)
    end
  
    # Return the final exports array. 
    Puppet.debug("Returning exports array. ")
    export_rules
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end


  def flush
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: Got to flush for resource #{@resource[:name]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")

    # Split the name on '/'
    policy_name, rule_index = @resource[:name].split(':')
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: Flushing for rule index #{rule_index} on Policy #{policy_name}")

    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_export.cmode: Ensure is absent.")

      # Destory the policy
      result = edel('policy-name', policy_name, 'rule-index', rule_index)

      Puppet.debug("Puppet::Provider::Netapp_export.cmode: export rule #{@resource[:name]} destroyed successfully. \n")
      return true
    
    when :present
      Puppet.debug("Puppet::Provider::Netapp_export.cmode: Ensure is present.")

      # Need to construct the export-rule-modify request
      export_rule_modify = NaElement.new('export-rule-modify')

      # Add values to it
      export_rule_modify.child_add_string("anonymous-user-id", @resource[:anonuid])
      export_rule_modify.child_add_string("client-match", @resource[:clientmatch])
      export_rule_modify.child_add_string("export-chown-mode", @resource[:exportchownmode])
      export_rule_modify.child_add_string("export-ntfs-unix-security-ops", @resource[:ntfsunixsecops])
      export_rule_modify.child_add_string("is-allow-dev-is-enabled", @resource[:allowdevenabled])
      export_rule_modify.child_add_string("is-allow-set-uid-enabled", @resource[:allowsetuid])
      export_rule_modify.child_add_string("policy-name", policy_name)
      export_rule_modify.child_add_string("rule-index", rule_index)

      # Process protocol array
      protocol_element = NaElement.new('protocol')
      @resource[:protocol].each do |protocol|
        protocol_element.child_add_string('access-protocol', protocol)
      end
      export_rule_modify.child_add(protocol_element)

      # Process rorule array
      rorule_element = NaElement.new('ro-rule')
      @resource[:rorule].each do |rorule|
        rorule_element.child_add_string('security-flavor', rorule)
      end unless @resource[:rorule].nil?
      export_rule_modify.child_add(rorule_element)

      # Process rwrule array
      rwrule_element = NaElement.new('rw-rule')
      @resource[:rwrule].each do |rwrule|
        rwrule_element.child_add_string('security-flavor', rwrule)
      end unless @resource[:rwrule].nil?
      export_rule_modify.child_add(rwrule_element)

      # Process superusersecurity array
      susecrule_element = NaElement.new('super-user-security')
      @resource[:superusersecurity].each do |susecrule|
        susecrule_element.child_add_string('security-flavor', susecrule)
      end unless @resource[:superusersecurity].nil?
      export_rule_modify.child_add(susecrule_element)

      # Modify the rule
      result = emodify(export_rule_modify)
  
      # Passed above, therefore must of worked.
      Puppet.debug("Puppet::Provider::Netapp_export.cmode: export rule #{@resource[:name]} modified successfully. \n")
      return true
      
    end #EOC
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: creating Netapp export rule #{@resource[:name]}.")

    # Split the name on '/'
    policy_name, rule_index = @resource[:name].split(':')
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: Flushing for rule index #{rule_index} on Policy #{policy_name}")

    # Need to construct the export-rule-create request
    export_rule_create = NaElement.new('export-rule-create')

    # Add values to it
    export_rule_create.child_add_string("anonymous-user-id", @resource[:anonuid])
    export_rule_create.child_add_string("client-match", @resource[:clientmatch])
    export_rule_create.child_add_string("export-chown-mode", @resource[:exportchownmode])
    export_rule_create.child_add_string("export-ntfs-unix-security-ops", @resource[:ntfsunixsecops])
    export_rule_create.child_add_string("is-allow-dev-is-enabled", @resource[:allowdevenabled])
    export_rule_create.child_add_string("is-allow-set-uid-enabled", @resource[:allowsetuid])
    export_rule_create.child_add_string("policy-name", policy_name)
    export_rule_create.child_add_string("rule-index", rule_index)

    # Process protocol array
    protocol_element = NaElement.new('protocol')
    @resource[:protocol].each do |protocol|
      protocol_element.child_add_string('access-protocol', protocol)
    end
    export_rule_create.child_add(protocol_element)

    # Process rorule array
    rorule_element = NaElement.new('ro-rule')
    @resource[:rorule].each do |rorule|
      rorule_element.child_add_string('security-flavor', rorule)
    end unless @resource[:rorule].nil?
    export_rule_create.child_add(rorule_element)

    # Process rwrule array
    rwrule_element = NaElement.new('rw-rule')
    @resource[:rwrule].each do |rwrule|
      rwrule_element.child_add_string('security-flavor', rwrule)
    end unless @resource[:rwrule].nil?
    export_rule_create.child_add(rwrule_element)

    # Process superusersecurity array
    susecrule_element = NaElement.new('super-user-security')
    @resource[:superusersecurity].each do |susecrule|
      susecrule_element.child_add_string('security-flavor', susecrule)
    end unless @resource[:superusersecurity].nil?
    export_rule_create.child_add(susecrule_element)

    # Add the export rule
    result = eadd(export_rule_create)

    # Passed above, therefore must of worked. 
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: export rule #{@resource[:name]}.")
    return true
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: destroying Netapp export rule #{@resource[:name]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_export.cmode: checking existance of Netapp export rule #{@resource[:name]}.")
    @property_hash[:ensure] == :present
  end

  
end
