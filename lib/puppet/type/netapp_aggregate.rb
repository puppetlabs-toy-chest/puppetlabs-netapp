Puppet::Type.newtype(:netapp_aggregate) do
  @doc = "Manage Netapp Aggregate creation, modification and deletion. [Family: cluster]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The aggregate name"
    isnamevar

    validate do |value|
      raise ArgumentError, "#{value} is invalid." unless value =~ /\w+/
    end
  end

  newproperty(:state) do
    desc "The aggregate state. Default value: 'Online'. Possible values: 'Online', 'Offline'."
    newvalues(:online, :offline)
    defaultto(:online)

    munge do |value|
      case value
      when 'creating'
        value = "online"
      else
        value
      end
    end
  end

  newparam(:blocktype) do
    desc "The indirect block format for the aggregate. Default value: '64_bit'. Possible values: '64_bit', '32_bit'."
    newvalues('64_bit', '32_bit')
    defaultto('64_bit')
  end

  newparam(:checksumstyle) do
    desc "Aggregate checksum style. Default value: 'block'. Possible values: 'advanced_zoned', 'block'"
    newvalues(:advanced_zoned, :block)
    defaultto(:block)
  end

  newproperty(:diskcount) do
    desc "Number of disks to place in the aggregate, including parity disks."

    validate do |value|
      raise ArgumentError, "Diskcount must be between 1 and 2147483647." unless value.to_i.between?(1,2147483647)
    end
  end

  newparam(:disksize) do
    desc "Disk size with unit to assign to aggregate."

    validate do |value|
      raise ArgumentError, 'Disk size must contain a valid unit.' unless value =~ /^\d*[TGMK]+/
    end
  end

  newparam(:disktype) do
    desc "Disk types to use with aggregate. Only required when multiple disk types are connected to filer.
    Possible values: 'ATA', 'BSAS', 'EATA', 'FCAL', 'FSAS', 'LUN', 'MSATA', 'SAS', 'SATA', 'SCSI', 'SSD', 'XATA', 'XSAS'"
    newvalues(:ATA, :BSAS, :EATA, :FCAL, :FSAS, :LUN, :MSATA, :SAS, :SATA, :SCSI, :SSD, :XATA, :XSAS)
  end

  newparam(:ismirrored, :boolean => :true) do
    desc "Should the aggregate be mirrored (have two plexes). Defaults to false. "
    newvalues(:true, :false)
    defaultto(:false)
  end

  newparam(:groupselectionmode) do
    desc "How should Data ONTAP add disks to raidgroups. Possible values: 'last', 'one', 'new', 'all'."
    newvalues(:last, :one, :new, :all)
  end

  newparam(:nodes, :array_matching => :all) do
    desc "Target nodes to create aggregate"
  end

  newparam(:raidsize) do
    desc "Maximum number of disks in each RAID group in aggregate. Valid values are between 2 and 28"

    validate do |value|
      raise ArgumentError, 'Raidsize must be between 2 and 28' unless value.to_i.between?(2, 28)
    end
  end

  newparam(:raidtype) do
    desc "Raid type to use in the new aggregate. Default: raid4. Possible values: raid4, raid_dp."
    newvalues(:raid4, :raid_dp)
    defaultto(:raid4)
  end

  newparam(:striping) do
    desc "Should the new aggregate be striped? Default: not_striped. Possible values: striped, not_striped."
    newvalues(:striped, :not_striped)
    defaultto(:not_striped)
  end

  newproperty(:option_free_space_realloc) do
    desc "Setting this option to 'on' enables free space reallocation (continuous segment cleaning) on a block checksum aggregate. Possible values : on, off, no_redirect 'on' : Free space reallocation enabled with automatically starting the redirect scanner 'off': Free space reallocate disabled 'no_redirect': Free space reallocation enabled without running the redirect scanner"
    newvalues(:on, :off, :no_redirect)
    defaultto(:off)
  end

  newproperty(:option_fs_size_fixed) do
    desc "Setting this option to 'on' causes the file system to remain the same size (and not grow) when the mirror is broken on a SnapMirrored aggregate (which MUST be embedded in a traditional volume), or when an 'aggr add' is performed on it. This option is automatically set to be 'on' when an aggregate becomes SnapMirrored. It remains 'on' after the 'snapmirror break' command is issued for an aggregate embedded in a traditional volume. This option allows an embedded aggregate to be SnapMirrored back to the source without needing to add disks to the source aggregate. If the aggregate size is larger than the file system size, turning off this option forces the file system to grow to the size of the aggregate. This option is not supported when the request is sent to the Admin Vserver LIF."
    newvalues(:on, :off)
  end

  newproperty(:option_ha_policy) do
    desc "This option is used to change the HA policy of given aggregate and restricted to clustered environments. It is not allowed in unclustered environments. Also this option does not apply to traditional volume. Changing the HA policy of an aggregate from SFO to CFO is allowed only in Maintenance mode. HA policy can not be changed if: 1. aggregate is striped. 2. aggregate contains node volumes. 3. aggregate is root. 4. aggregate is partner aggregate during takeover i.e. when it is not home to local node. EOP_CLUSTER_ATTR_DISALLOWED is returned if this option is used in unclustered environments. EOP_DISALLOWED_ON_STRIPED_AGGR is returned if this option is used with striped aggregate. EOP_DISALLOWED_ON_AGGR_WITH_NODE_VOLS is returned if this option is used on aggregate which contains node volumes. EOP_DISALLOWED_ON_ROOT_AGGR is returned if this option is used on root aggregate. EOP_DISALLOWED_ON_NOT_HOME_AGGR is returned if this option is used on partner aggregate during takeover."
    newvalues(:sfo, :cfo)
  end

  newproperty(:option_ignore_inconsistent) do
    desc "This command can only be used in maintenance mode. If this option is set to 'on', then the root aggregate may be brought online when booting even if it is marked as inconsistent. The user is cautioned that bringing it online prior to running WAFL_check or wafliron may result in further file system inconsistency. This option is not supported when the request is sent to the Admin Vserver LIF."
    newvalues(:on, :off)
  end

  newproperty(:option_lost_write_protect) do
    desc "Setting this option to 'off' disables lost write protection on the aggregate. The default is 'on'. The user is cautioned that turning off this option may expose the filesystem(s) contained in the aggregate to data loss and data corruption. This option should not be disabled, unless directed to do so by support personnel."
    newvalues(:on, :off)
  end

  newproperty(:option_max_write_alloc_blocks) do
    desc "The maximum number of blocks used for write allocation. Some sequential read workloads may benefit from increasing this value. Default value is 0 which uses the controller-wide default value of 64. The default is optimal for most users. The controller-wide default can be adjusted with the bootarg 'wafl-max-write-alloc-blocks'"
  end

  newproperty(:option_striping) do
    desc "This option sets the striping information of given aggregate. It is restricted to clustered environments and not allowed in unclustered environments. When set to true, it marks given aggregate as member of stripe. This option is not allowed if given aggregate is of 'cfo' HA policy. Also this option does not apply to traditional volume. EOP_CLUSTER_ATTR_DISALLOWED is returned if this option is used in unclustered environments. EOP_DISALLOWED_ON_CFO_AGGR is returned if given aggregate is of 'cfo' HA policy. This option is not supported when the request is sent to the Admin Vserver LIF."
    newvalues(:striped, :not_striped)
  end

  newproperty(:option_nosnap) do
    desc "Setting this option to 'on' disables automatic snapshots on the aggregate."
    newvalues(:on, :off)
  end

  newproperty(:option_raid_cv) do
    desc "Setting this option to 'off' disables block or advanced_zoned checksum (azcs) protection on the aggregate. The default is 'on'. The user is cautioned that turning off this option exposes the filesystems contained in the aggregate to inconsistency that could be caused by a misbehaving hardware component in the system."
    newvalues(:on, :off)
  end

  newproperty(:option_raid_lost_write) do
    desc "Setting this option to 'off' disables RAID Lost Write protection on the aggregate. The default is 'on'. The user is cautioned that turning off this option may expose the filesystem(s) contained in the aggregate to data loss and data corruption. The option should not be disabled, unless directed to do so by support personnel."
    newvalues(:on, :off)
  end

  newproperty(:option_raid_zoned) do
    desc "Setting this option to 'off' disables zoned checksum protection on the aggregate. The default is 'on'. The user is cautioned that turning off this option exposes the filesystems contained in the aggregate to inconsistency that could be caused by a misbehaving hardware component in the system."
    newvalues(:on, :off)
  end

   newproperty(:option_raidsize) do
    desc "The maximum size of a RAID group within the aggregate. Changing this option doesn't cause existing RAID groups to grow or shrink. Rather, it only affects whether more disks will be added to the last existing RAID group in the future, and how large new RAID groups will be."
  end

  newproperty(:option_cache_raid_group_size) do
    desc "The current maximum size of a SSD RAID group within the hybrid aggregate. This option can only be modified for hybrid aggregate. Changing this option doesn't cause existing RAID groups to grow or shrink. Rather, it only affects whether more disks will be added to the existing SSD RAID group in the future, and how large new SSD RAID groups will be."
  end

  newproperty(:option_raidtype) do
    desc "The type of RAID group used for this aggregate. The 'raid4' setting provides one parity disk per RAID group, while 'raid_dp' provides two. Changing this option immediately changes the RAID group type for all RAID groups in the aggregate. When upgrading RAID groups from 'raid4' to 'raid_dp', each RAID group begins a reconstruction onto a spare disk allocated for the second 'dparity' parity disk."
    newvalues(:raid4, :raid_dp, :raid0)
  end

  newproperty(:option_resyncsnaptime) do
    desc "Sets the mirror resynchronization snapshot frequency to be the given number of minutes. The default value is 60 (minutes)."
  end
  newproperty(:option_root) do
    desc "The specified aggregate is to become the root aggregate for the filer on the next reboot. This option can be used only in maintenance mode and on only one aggregate at any given time. The existing root aggregate will become a non-root aggregate after the reboot. Until the system is rebooted, the original aggregate will continue to show root as an option, and the new root aggregate will show diskroot as an option. In general, the aggregate that has the diskroot option is the one that becomes the root aggregate following the next reboot. The only way to remove the root status of an aggregate is to set it on another aggregate. In clustered environments, this option is not allowed with aggregates with 'sfo' HA policy as root has to be an aggregate with 'cfo' HA policy. EOP_DISALLOWED_ON_SFO_AGGR is returned if given aggregate is of 'sfo' HA policy."
  end

  newproperty(:option_snapmirrored) do
    desc "If SnapMirror is enabled, the filer auto- matically sets this option to 'on'. Set this option to 'off' with the 'snapmirror' command if SnapMirror should no longer be used to update the mirror. After setting this option to 'off', the mirror becomes a regular writable aggregate, and all its volumes are restored to whatever state they were last in. Note that it is not possible to set this option directly through this interface. Rather, it is automatically changed as a side effect of running the appropriate 'snapmirror' commands. This option is not supported when the request is sent to the Admin Vserver LIF."
    newvalues(:on, :off)
  end

  newproperty(:option_snapshot_autodelete) do
    desc "Setting this option to 'off' disables automatic snapshot deletion on the aggregate."
    newvalues(:on, :off)
  end

  newproperty(:option_thorough_scrub) do
    desc "Setting this option to 'on' enables thorough scrub on a block checksum aggregate. That means that a scrub will initialize any zeroed checksum entries that it finds. If there are any checksum entries to be initialized, scrub will run slower than normal."
    newvalues(:on, :off)
  end

  newproperty(:option_percent_snapshot_space) do
    desc "Percentage of total blocks in the aggregate reserved for snapshots."
  end

  newproperty(:option_nearly_full_threshold) do
    desc "Threshold of used space as a percentage of aggregate size for which to emit aggregate nearly full warning. The default value is 95%. The maximum value for this option is 99%. It must be less than the full_threshold. Setting this threshold to 0 disables the alert."
  end

  newproperty(:option_full_threshold) do
    desc "Threshold of used space as a percentage of aggregate size for which to emit aggregate full warning. The default value is 98%. The maximum value for this option is 100%. It must be greater than the nearly_full_threshold. Setting this threshold to 0 disables the alert."
  end

  newproperty(:option_is_flash_pool_caching_enabled) do
    desc "Setting this option to 'false' will disable the caching on the Flash Pool while setting 'true' will enable the caching again on the Flash Pool. Changing this option will have no effect on individual caching policies associated with the volumes under this Flash Pool."
    newvalues(:true, :false)
  end

  newproperty(:option_hybrid_enabled) do
    desc "Setting this option to 'true' would mark the aggregate as hybrid_enabled. That means the aggregate can contain a mix of SSDs and HDDs(Hard Disk Drives, e.g., SAS, SATA, and/or FC). The operation can be forced by using the hybrid_enabled_force option for the aggregates having flexvols which cannot be write cached. EAGGR_CANT_UNDO_HYBRID is returned when we are trying to set the option hybrid_enabled to false on an aggregate that already contains a mix of HDDs and SSDs. EAGGR_HYBRID is returned when we are trying to set option hybrid_enabled to true on an aggregate which is already hybrid. EOP_DISALLOWED_WORM_HYBRID_AGGR is returned when we are trying to set option hybrid_enabled to true on an snaplock aggregate. ERAID_HYA_SUPPORT_DISABLED is returned when the partner node in HA pair is running a version of Data ONTAP which does not support hybrid aggregates. EOP_DISALLOWED_ON_SSD_AGGR is returned if this option is used on aggregates created out of SSD disks. EOP_DISALLOWED_HYA_ON_RAID0_AGGR is returned if this option is used on raid0 aggregates. EOP_DISALLOWED_HYA_ON_ZONED_AGGR is returned if this option is used on aggregates with zoned checksums. EOP_DISALLOWED_HYA_ON_LUNS_AGGR is returned if this option used on aggregates created out of LUNs."
    newvalues(:true, :false)
  end

  newproperty(:option_hybrid_enabled_force) do
    desc "Setting this option to 'true' would mark the aggregate as hybrid_enabled. That means the aggregate can contain a mix of SSDs and HDDs(Hard Disk Drives, e.g., SAS, SATA, and/or FC). This option is used for force marking of aggregates having flexvols which cannot be write cached as hybrid enabled. FlexVols in the aggregate marked as hybrid enabled using this option which cannot participate in write-caching only have read-caching enabled. All other flexvols in the aggregate can participate in both read and write caching. EAGGR_CANT_UNDO_HYBRID is returned when we are trying to set the option hybrid_enabled_force to false on an aggregate that already contains a mix of HDDs and SSDs. EAGGR_HYBRID is returned when we are trying to set option hybrid_enabled_force to true on an aggregate which is already hybrid. EOP_DISALLOWED_WORM_HYBRID_AGGR is returned when we are trying to set option hybrid_enabled_force to true on an snaplock aggregate. ERAID_HYA_SUPPORT_DISABLED is returned when the partner node in HA pair is running a version of Data ONTAP which does not support hybrid aggregates. EOP_DISALLOWED_ON_SSD_AGGR is returned if this option is used on aggregates created out of SSD disks. EOP_DISALLOWED_HYA_ON_RAID0_AGGR is returned if this option is used on raid0 aggregates. EOP_DISALLOWED_HYA_ON_ZONED_AGGR is returned if this option is used on aggregates with zoned checksums."
    newvalues(:true, :false)
  end

 # Validate provided parameters
  validate do
  end

end
