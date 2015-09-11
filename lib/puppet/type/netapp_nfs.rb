Puppet::Type.newtype(:netapp_nfs) do
  @doc = "Manage Netap NFS service. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:vserver) do
    desc "NFS service SVM"
    isnamevar
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
