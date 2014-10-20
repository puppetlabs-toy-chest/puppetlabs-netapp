require 'puppet/parameter/boolean'

Puppet::Type.newtype(:netapp_export_rule) do 
  @doc = "Manage Netapp CMode Export rule creation, modification and deletion."
  
  apply_to_device
  
  ensurable
  
  newparam(:name) do
    desc "The export policy. Composite name based on policy name and rule index." 
    isnamevar
    #TODO: Add validation
#    validate do |value|
#    	unless value =~ /^(\/[\w]+){2,3}$/
#        raise ArgumentError, "%s is not a valid export name." % value
#     end
#    end
  end
  
  newproperty(:anonuid) do 
    desc "User name or ID to map anonymous users to. Defaults to 65534."
    defaultto '65534'
    validate do |value|
      raise ArgumentError, "Anonuid should be a string." unless value.is_a?String
    end
    
#    def insync?(is)
      # Should is an array, so pull first value.
#      should = @should.first

#      return false unless is == should

      # Got here, so must match
#      return true
#    end
  end
  
  newproperty(:clientmatch) do
    desc "Client match specification for the export rule."
    validate do |value|
      raise ArgumentError, "Clientmatch should be a string." unless value.is_a?String
    end
  end

  newproperty(:exportchownmode) do
    desc "Change ownership mode. Possible values are 'restricted', 'unrestricted'. Defaults to 'restricted'."
    newvalues(:restricted, :unrestricted)
    defaultto(:restricted)
  end

  newproperty(:ntfsunixsecops) do
    desc "Ignore/Fail Unix security operations on NTFS volumes. Possible values are 'fail', 'ignore'. Defaults to 'fail'."
    newvalues(:ignore, :fail)
    defaultto(:fail)
  end

  #newproperty(:allowdevenabled, :boolean => true, :parent => Puppet::Parameter::Boolean) do
  newproperty(:allowdevenabled, :boolean => true) do
    desc "Should the NFS server allow creation of devices. Defaults to true."
    newvalues(:true, :false)
    defaultto(:true)
  end

  #newproperty(:allowsetuid, :boolean => true, :parent => Puppet::Parameter::Boolean) do
  newproperty(:allowsetuid, :boolean => true) do
    desc "Should the NFS server allow setuid. Defaults to true."
    newvalues(:true, :false)
    defaultto(:true)
  end

  newproperty(:protocol, :array_matching => :all) do
    desc "Client access protocol. Defaults to 'any'. Possible values: 'any', 'nfs2', 'nfs3', 'nfs', 'cifs', 'nfs4', 'flexcache'."
    newvalues(:any, :nfs2, :nfs3, :nfs, :cifs, :nfs4, :flexcache)
    defaultto(:any)

    validate do |value|
      #TODO: Need to validate provided values. 
    end

    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # Check the first value to see if 'all_hosts'.
      if is.first == 'all_hosts' && @should.first == 'all_hosts'
        return true
      else
        # If they were different lengths, they are not equal.
        return false unless is.length == @should.length

        # Check that is and @should are the same...
        return (is == @should or is == @should.map(&:to_s))

      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:rorule, :array_matching => :all) do
    desc "Read only rule. Defaults to 'any'. Possible values: 'any', 'none', 'never', 'krb5', 'ntlm', 'sys', 'spinauth'."
    newvalues(:any, :none, :never, :never, :krb5, :ntlm, :sys, :spinauth)

    validate do |value|
      #TODO: Need to validate provided values. 
    end

    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # Check the first value to see if 'all_hosts'.
      if is.first == 'all_hosts' && @should.first == 'all_hosts'
        return true
      else
        # If they were different lengths, they are not equal.
        return false unless is.length == @should.length

        # Check that is and @should are the same...
        return (is == @should or is == @should.map(&:to_s))

      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:rwrule, :array_matching => :all) do
    desc "Read write rule. Defaults to 'any'. Possible values: 'any', 'none', 'never', 'krb5', 'ntlm', 'sys', 'spinauth'."
    newvalues(:any, :none, :never, :never, :krb5, :ntlm, :sys, :spinauth)

    validate do |value|
      #TODO: Need to validate provided values. 
    end

    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # Check the first value to see if 'all_hosts'.
      if is.first == 'all_hosts' && @should.first == 'all_hosts'
        return true
      else
        # If they were different lengths, they are not equal.
        return false unless is.length == @should.length

        # Check that is and @should are the same...
        return (is == @should or is == @should.map(&:to_s))

      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:superusersecurity, :array_matching => :all) do
    desc "Superuser security flavor. Defaults to 'any'. Possible values: 'any', 'none', 'never', 'krb5', 'ntlm', 'sys', 'spinauth'."
    newvalues(:any, :none, :never, :never, :krb5, :ntlm, :sys, :spinauth)

    validate do |value|
      #TODO: Need to validate provided values. 
    end

    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # Check the first value to see if 'all_hosts'.
      if is.first == 'all_hosts' && @should.first == 'all_hosts'
        return true
      else
        # If they were different lengths, they are not equal.
        return false unless is.length == @should.length

        # Check that is and @should are the same...
        return (is == @should or is == @should.map(&:to_s))

      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  # Make sure that ReadOnly and ReadWrite aren't the same values. 
  validate do
    #raise ArgumentError, "Readonly and Readwrite params cannot be the same." if self[:readwrite] == self[:readonly]
  end
  
  # # Autorequire any matching netapp_volume resources. 
  # autorequire(:netapp_volume) do
  #   requires = []
  #   [self[:name], self[:path]].compact.each do |path|
  #     if match = %r{/\w+/(\w+)(?:/\w+)?$}.match(path)
  #       requires << match.captures[0]
  #     end
  #   end
  #   requires
  # end
  
  
end
