Puppet::Type.newtype(:netapp_storage_failover) do
  @doc = 'Manage Netapp storage failover. [Family: cluster]'

  apply_to_device

  newparam(:name) do
    desc 'The node name'
    isnamevar
    validate do |value|
      raise ArgumentError, '%s is a invalid node name' % value unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:auto_giveback) do
    desc 'Auto Giveback Enabled'
    newvalues(:true, :false)
  end

  newproperty(:auto_giveback_after_panic) do
    desc 'Auto giveback after takeover on panic'
    newvalues(:true, :false)
  end

  newproperty(:auto_giveback_override_vetoes) do
    desc 'Auto-giveback Override Vetoes Enabled'
    newvalues(:true, :false)
  end
end
