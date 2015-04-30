Puppet::Type.newtype(:netapp_lun_map) do
  @doc = "Manage Netap Lun map creation and deletion."

  apply_to_device

  ensurable

  newparam(:lunmap) do
    desc "Lun map - Composite key of format {path}:{lun-id}."
    isnamevar

    validate do |value|
      raise ArgumentError, "#{value} is an invalid Lun map." unless value =~ /(\/\w+){3,4}:\d{1,4}/
      lun_id = value.split(':').last
      raise ArgumentError, "#{lun_id} is an invalid lun ID" unless lun_id.to_i.between?(1,4095)
    end
  end

  newparam(:initiatorgroup) do
    desc "Initiator group to map to."
  end

  ## Validate params
  validate do
    raise ArgumentError, 'Initiatorgroup is required' if self[:initiatorgroup].nil?
  end

  ## Autorequire resources
  # Netapp_lun resources
  autorequire(:netapp_lun) do
    path = self[:lunmap].split(':').first
  end

end
