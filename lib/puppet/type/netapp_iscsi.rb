Puppet::Type.newtype(:netapp_iscsi) do
  @doc = "Manage Netap ISCSI service. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:svm) do
    desc "ISCSI service SVM"
    isnamevar
  end

  newproperty(:target_alias) do
    desc "ISCSI WWPN Alias"
  end

  newproperty(:state) do
    desc "ISCSI service state."
    newvalues(:on, :off)
  end
end
