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

  newproperty(:showmount) do
    desc "Enable or Disable showmount."
    newvalues(:enabled, :disabled)
  end

  newproperty(:v3msdosclient) do
    desc "Control Access for Win clients."
    newvalues(:enabled, :disabled)
  end

  newproperty(:v364bitidentifiers) do
    desc "Control 64bit file identifiers for v3."
    newvalues(:enabled, :disabled)
  end

  newproperty(:v4numericids) do
    desc "Control handling of user IDs."
    newvalues(:enabled, :disabled)
  end

  newproperty(:v41pnfs) do
    desc "Control NFS v4.1 pnfs."
    newvalues(:enabled, :disabled)
  end
 
  newproperty(:nfsv4iddomain) do
    desc "NFSv4 Domain name"
  end

  newproperty(:v41referrals) do
    desc "Control NFS v4.1 referrals."
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
