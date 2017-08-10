Puppet::Type.newtype(:netapp_nfs) do
  @doc = "Manage Netap NFS service. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:vserver) do
    desc "NFS service SVM"
    isnamevar
    validate do |value|
      raise ArgumentError, 'A Vserver name can only contain alphanumeric characters and ".", "-" or "_"' unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:state) do
    desc "NFS service state."
    newvalues(:on, :off)
  end

  newproperty(:v3) do
    desc "Control NFS v3 access."
    newvalues(:enabled, :disabled)
  end

  newproperty(:v40) do
    desc "Control NFS v4.0 access."
    newvalues(:enabled, :disabled)
  end

  newproperty(:v41) do
    desc "Control NFS v4.1 access."
    newvalues(:enabled, :disabled)
  end

  newproperty(:auth_sys_extended_groups) do
    desc "AUTH_SYS Extended Groups enabled."
    newvalues(:enabled, :disabled)
  end

  newproperty(:enable_ejukebox) do
    desc "Enable NFSv3 EJUKEBOX error."
    defaultto :false
    newvalues(:true, :false)
  end

  #newproperty(:udp) do
  #  desc "Control NFS v4.1 access."
  #  newvalues(:enabled, :disabled)
  #end

  #newproperty(:tcp) do
  #  desc "Control NFS v4.1 access."
  #  newvalues(:enabled, :disabled)
  #end

  #newproperty(:default_win_user) do
  #  desc "The default windows user for CIFS access."
  #end

  #newproperty(:default_win_group) do
  #  desc "The default windows group for CIFS access."
  #end
end
