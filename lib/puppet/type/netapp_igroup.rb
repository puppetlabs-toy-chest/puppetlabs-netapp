Puppet::Type.newtype(:netapp_igroup) do
  @doc = "Manage Netapp ISCSI initiator groups [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "initiator group name"
    isnamevar
  end

  newproperty(:group_type) do
    desc "initiator group type"
    newvalues(:fcp,:iscsi,:mixed)
  end

  newproperty(:os_type) do
    desc "OS type of the initiators within the group. The os type applies to all initiators within the group and governs the finer details of SCSI protocol interaction with these initiators. Required."
    newvalues(:solaris,:windows,:hpux,:aix,:linux,:netware,:vmware,:openvms,:xen,:hyper_v)
  end

  newproperty(:members,:array_matching => :all) do
    desc "An array of WWPN or Alias initiator members of the group"
    def insync?(is)
      is = [] if is == :absent
      @should.sort == is.sort
    end
  end

  newproperty(:portset) do
    desc "portset that is bound to the initiator group  A value of `false` will unbind the portset. Valid values are a string or `false`"
  end

  newproperty(:force) do
    desc "Forcibly remove the initiator even if there are existing LUNs mapped to this initiator group. Best practice is to attempt to unmap all the luns associated with a group before removing the initiator. Default to false"
    newvalues(:false, :true)
  end
end
