Puppet::Type.newtype(:netapp_vserver_cifs_options) do
  @doc = 'Manage Netapp Vserver CIFS options. [Family: vserver]'

  apply_to_device

  newparam(:name) do
    desc 'vserver name'
    isnamevar
    validate do |value|
      raise ArgumentError, 'A Vserver name can only contain alphanumeric characters and ".", "-" or "_"' unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:max_mpx) do
    desc 'Maximum simultaneous operations per TCP connection. Defaults to 255.'
    defaultto '255'
    validate do |value|
      raise ArgumentError, 'The value for maximum simultaneous operations per TCP connection must be in between 2 to 65535.' unless value.to_i.between?(2, 65535)
    end
  end

  newproperty(:smb2_enabled) do
    desc 'Enable all SMB2 Protocols. Defaults to true.'
    defaultto 'true'
    newvalues(:true, :false)
  end
end
