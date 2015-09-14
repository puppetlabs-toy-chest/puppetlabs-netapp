Puppet::Type.newtype(:netapp_license) do
  @doc = "Manage Netapp Licenses. Only supported by ONTAP 8.2 and newer. [Family: cluster]"

  apply_to_device

  ensurable

  newparam(:package) do
    desc "Package Possible values:
'base' - Cluster Base License,
'nfs' - NFS License,
'cifs' - CIFS License,
'iscsi' - iSCSI License,
'fcp' - FCP License,
'snaprestore' - SnapRestore License,
'snapmirror' - SnapMirror License,
'flexclone' - FlexClone License,
'snapvault' - SnapVault License,
'snaplock' - SnapLock License,
'snapmanagersuite' - SnapManagerSuite License,
'snapprotectapps' - SnapProtectApp License,
'v_storageattach' - Virtual Attached Storage License"
    isnamevar
  end

  newparam(:codes) do
    desc "The license code"
  end
end
