Puppet::Type.newtype(:netapp_snapmirror) do
  @doc = "Manage Netapp Snapmirror creation, modification and deletion."

  apply_to_device

  ensurable do
    desc "Netapp Snapmirror resource state. Valid values are: present, absent."

    defaultto(:present)

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  newproperty(:source_location) do
    desc "The source location."
  end

  newparam(:source_snapshot) do
    desc "The source snapshot name"
  end

  newparam(:destination_location) do
    desc "The destination location."
    isnamevar
  end

  newparam(:destination_snapshot) do
    desc "The destination snapshot."
  end

  newproperty(:max_transfer_rate) do
    desc "The max transfer rate, in KB/s. Defaults to unlimited."
  end

  newproperty(:relationship_type) do
    desc "Specifies the type of the SnapMirror relationship. An extended data protection relationship with a policy of type vault is equivalent to a 'vault' relationship. On Data ONTAP 8.3.1 or later, in the case of a Vserver SnapMirror relationship the type of the relationship is always data_protection. Possible values:
data_protection ,
load_sharing ,
vault ,
restore ,
transition_data_protection ,
extended_data_protection"
  end
end
