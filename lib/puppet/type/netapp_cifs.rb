Puppet::Type.newtype(:netapp_cifs) do
  @doc = 'Manage Netapp CIFS server. [Family: vserver]'
  apply_to_device

  ensurable

  newparam(:name) do
    desc 'cifs server name'
    isnamevar
    validate do |value|
      raise ArgumentError, '#{value} is an invalid cifs server name' unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:domain) do
    desc 'Fully qualified domain name of the Windows Active Directory this CIFS server belongs to.'
  end

  newproperty(:admin_username) do
    desc 'Username for the account used to add this CIFS server to the Active Directory.'
  end

  newproperty(:admin_password) do
    desc 'Password for the account used to add this CIFS server to the Active Directory.'
  end
end
