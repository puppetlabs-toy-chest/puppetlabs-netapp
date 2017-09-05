Puppet::Type.newtype(:netapp_vserver_cifs_domain_password_schedule) do
  @doc = 'Manage Netapp vserver cifs domain password schedule. [Family: vserver]'

  apply_to_device

  newparam(:name) do
    desc 'The Vserver name'
    isnamevar
    validate do |value|
      raise ArgumentError, 'A Vserver name can only contain alphanumeric characters and ".", "-" or "_"' unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:schedule_randomized_minute) do
    desc 'Minutes within which schedule start can be randomized'
    validate do |value|
      raise ArgumentError, '%s is not a valid schedule randomized minute.' % value unless value =~ /^\d+$/
      raise ArgumentError, 'Schedule randomized minute value must be in between 1 and 180.' unless value.to_i.between?(1, 180)
    end

    munge do |value|
      case value
      when String
        if value =~ /^[0-9]+$/
          value = Integer(value)
        end
      end

      return value
    end
  end
end
