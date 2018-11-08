Puppet::Type.newtype(:netapp_volume) do
  @doc = "Manage Netapp Volume creation, modification and deletion. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The volume name. Valid characters are a-z, 1-9 & underscore."
    isnamevar
    validate do |value|
      unless value =~ /^\w+$/
        raise ArgumentError, "%s is not a valid volume name." % value
      end
    end
  end

  newproperty(:comment) do
    desc "The volume comment. Valid characters are UTF-8 characters."
  end

  newproperty(:state) do
    desc "The volume state. Valid options are: online, offline, restricted."
    newvalues(:online, :offline, :restricted)
  end

  newproperty(:initsize) do
    desc "The initial volume size. Valid format is [0-9]+[kmgt]."
    validate do |value|
      unless value =~ /^\d+[kmgt]$/
         raise ArgumentError, "%s is not a valid initial volume size." % value
      end
    end
  end

  newparam(:aggregate) do
    desc "The aggregate this volume should be created in."
    isrequired
    validate do |value|
      unless value =~ /^\w+$/
        raise ArgumentError, "%s is not a valid aggregate name." % value
      end
    end
  end

  newparam(:languagecode) do
    desc "The language code this volume should use."
    newvalues(:C, :ar, :cs, :da, :de, :en, :en_US, :es, :fi, :fr, :he, :hr, :hu, :it, :ja, :ja_v1, :ko, :no, :nl, :pl, :pt, :ro, :ru, :sk, :sl, :sv, :tr, :zh, :zh_TW)
  end

  newparam(:spaceres) do
    desc "The space reservation mode."
    newvalues(:none, :file, :volume)
  end

  newproperty(:snapreserve) do
    desc "The percentage of space to reserve for snapshots."

    validate do |value|
      raise ArgumentError, "%s is not a valid snapreserve." % value unless value =~ /^\d+$/
      raise ArgumentError, "Puppet::Type::Netapp_volume: Reserved percentage must be between 0 and 100." unless value.to_i.between?(0,100)
    end

    munge do |value|
      case value
      when String
        if value =~ /^[-0-9]+$/
          value = Integer(value)
        end
      end

      return value
    end
  end

  newproperty(:junctionpath) do
    desc "The fully-qualified pathname in the owning Vserver's namespace at which a volume is mounted."
    newvalues(/^\//,false)
    munge do |value|
      case value
      when false, :false, "false"
        :false
      else
        value
      end
    end
  end

  newproperty(:autosize, :boolean => true) do
    desc "Should volume autosize be grow, grow_shrink, or off?"
    newvalues(:off, :grow, :grow_shrink)
  end

  newproperty(:exportpolicy) do
    desc "The export policy with which the volume is associated."
  end

  newproperty(:qospolicy) do
    desc "The QoS policy with which the volume is associated."
    validate do |value|
      unless value =~ /^\S+$/
        raise ArgumentError, "%s is not a valid qospolicy name." % value
      end
    end
  end

  newparam(:volume_type) do
    desc "The type of the volume to be created. Possible values:
rw - read-write volume (default setting),
ls - load-sharing volume,
dp - data-protection volume,
dc - data-cache volume (FlexCache)"
    newvalues(:rw, :ls, :dp, :dc)
  end

  newproperty(:group_id) do
    desc "The UNIX group ID for the volume."

    validate do |value|
      raise ArgumentError, "%s is not a valid group_id." % value unless value =~ /^\d+$/
    end
  end

  newproperty(:user_id) do
    desc "The UNIX user ID for the volume."

    validate do |value|
      raise ArgumentError, "%s is not a valid user_id." % value unless value =~ /^\d+$/
    end
  end

  newproperty(:unix_permissions) do
    desc "Unix permission bits in octal string format.It's similar to Unix style permission bits: In Data ONTAP 7-mode, the default setting of '0755' gives read/write/execute permissions to owner and read/execute to group and other users. In Data ONTAP Cluster-Mode, for security style 'mixed' or 'unix', the default setting of '0755' gives read/write/execute permissions to owner and read/execute permissions to group and other users. For security style 'ntfs', the default setting of '0000' gives no permissions to owner, group and other users. It consists of 4 octal digits derived by adding up bits 4, 2 and 1. Omitted digits are assumed to be zeros. First digit selects the set user ID(4), set group ID (2) and sticky (1) attributes. The second digit selects permission for the owner of the file: read (4), write (2) and execute (1); the third selects permissions for other users in the same group; the fourth for other users not in the group."

    validate do |value|
      raise ArgumentError, "%s is not a valid unix_permissions." % value unless value =~ /^\d+$/
    end
  end

  newproperty(:options, :array_matching => :all) do
    desc "The volume options hash."
    validate do |value|
      raise ArgumentError, "Puppet::Type::Netapp_volume: options property must be a hash." unless value.is_a? Hash
    end

    def insync?(is)
      # @should is an Array. see lib/puppet/type.rb insync?
      should = @should.first

      # Comparison of hashes
      return false unless is.class == Hash and should.class == Hash
      should.each do |k,v|
        return false unless is[k] == should[k]
      end
      true
    end

    def should_to_s(newvalue)
      # Newvalue is an array, but we're only interested in first record.
      newvalue = newvalue.first
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:snapshot_policy) do
    desc "The name of the snapshot policy. The default policy name is 'default'."
  end

  newproperty(:snapshot_diraccess, :boolean => true) do
    desc "Should access to the snapshot directory be on or off?"
    newvalues(:true, :false)
  end

  autorequire(:netapp_export_policy) do
    self[:exportpolicy]
  end

  ## Validate required params
  validate do
    raise ArgumentError, 'aggregate is required' if self[:aggregate].nil? and self.provider.aggregate.nil?
  end
end
