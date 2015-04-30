Puppet::Type.newtype(:netapp_aggregate) do
  @doc = "Manage Netapp Aggregate creation, modification and deletion."

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
        value = :online
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

  # Validate provided parameters
  validate do
  end

end
