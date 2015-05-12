Puppet::Type.newtype(:netapp_vserver) do
  @doc = "Manage Netapp Vserver creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The vserver name"
    isnamevar

    validate do |value|
      #TODO: Add vserver name validation. Should be FQDN format
    end
  end

  newproperty(:state) do
    desc "The vserver state"

    newvalues(:stopped, :running)
    defaultto(:running)

    munge do |value|
      case value
      when 'starting'
        value = :running
      when 'stopping'
        value = :stopped
      when 'initializing'
        value = :running
      end
    end
  end

  newparam(:rootvol) do
    desc "The vserver root volume"
    isrequired
  end

  newparam(:rootvolaggr) do
    desc "Vserver root volume aggregate"
    isrequired
  end

  newparam(:rootvolsecstyle) do
    desc "Vserver root volume security style"
    isrequired

    newvalues(:unix, :ntfs, :mixed, :unified)
  end

  newproperty(:comment) do
    desc "Vserver comment"
  end

  newparam(:language) do
    desc "Vserver language"

    newvalues("c", "c.UTF-8", "ar", "cs", "da", "de", "en", "en_us", "es", "fi", "fr", "he",
      "hr", "hu", "it", "ja", "ja_v1", "ja_jp.pck", "ja_jp.932", "ja_jp.pck_v2", "ko",
      "no", "nl", "pl", "pt", "ro", "ru", "sk", "sl", "sv", "tr", "zh", "zh.gbk", "zh_tw")
    defaultto("c.UTF-8")
  end

  newproperty(:namemappingswitch, :array_matching => :all) do
    desc "Vserver name mapping switch. Defaults to 'file'."

    newvalues(:file, :ldap)
    #defaultto([:file])
    #
    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.map!(&:to_sym).inspect
    end
  end

  newproperty(:nameserverswitch, :array_matching => :all) do
    desc "Vserver name server switch. Defaults to 'file'."

    newvalues(:file, :ldap, :nis)
    defaultto([:file])

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.map!(&:to_sym).inspect
    end
  end

  newproperty(:quotapolicy) do
    desc "Vserver quota policy"
  end

  newproperty(:snapshotpolicy) do
    desc "Vserver snapshot policy"
  end

  newproperty(:maxvolumes) do
    desc "Vserver maximum allowed volumes."
  end

  newproperty(:aggregatelist, :array_matching => :all) do
    desc "Vserver aggregate list. Must be an array."

    validate do |value|
      raise ArgumentError, "#{value} is an invalid aggregate value." unless value =~ /([\w]+)/
    end

    # munge do |value|
    #   debug("Value is a #{value.class}. Contents = #{value.inspect}.")
    #   if value.is_a?(String) and value.include?(',')
    #     value = value.split(',').map!(&:strip)
    #   end
    #   debug("New value = #{value.inspect}.")
    #   value
    # end

    def insync?(is)
      # Check that the arrays are same length
      return false unless is.length == @should.length

      # Check that is and @should are the same...
      return (is == @should or is == @should.map(&:to_s))
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:allowedprotos, :array_matching => :all) do
    desc "Vserver allowed protocols"
    newvalues(:nfs, :cifs, :fcp, :iscsi, :ndmpd)

    def insync?(is)
      # Check that the arrays are same length
      return false unless is.length == should.length

      # Check that is and @should are the same...
      return (is == should or is == should.map(&:to_s))
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.map!(&:to_sym).inspect
    end
  end


  ## Validate required params
  validate do
    raise ArgumentError, 'Rootvol is required' if self[:rootvol].nil? and self.provider.rootvol.nil?
    raise ArgumentError, 'Rootvolaggr is required' if self[:rootvolaggr].nil? and self.provider.rootvolaggr.nil?
    raise ArgumentError, 'Rootvolsecstyle is required' if self[:rootvolsecstyle].nil? and self.provider.rootvolsecstyle.nil?
  end

  ## Autorequire resources
  # Aggregates
  autorequire(:netapp_aggregate) do
    requires = []

    # Add the rootvolaggr
    requires << self[:rootvolaggr]

    # Itterate aggregatelist and require matching resources
    Array(self[:aggregatelist]).each do |aggregate|
      requires << aggregate
    end

    requires
  end

end

