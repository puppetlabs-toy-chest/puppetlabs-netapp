Puppet::Type.newtype(:netapp_export_policy) do 
  @doc = "Manage Netapp CMode Export Policy creation and deletion."
  
  apply_to_device
  
  ensurable
  
  newparam(:name) do
    desc "The export policy name."
    isnamevar
    validate do |value|
    	unless value =~ /^[\w]+$/
        raise ArgumentError, "%s is not a valid export policy name." % value
      end
    end
  end
  
end
