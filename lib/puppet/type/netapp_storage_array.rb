Puppet::Type.newtype(:netapp_storage_array) do
  @doc = 'Manage storage array. [Family: cluster]'

  apply_to_device

  newparam(:name) do
    desc 'The storage array name'
    isnamevar
    validate do |value|
      raise ArgumentError, '#{value} is an invalid storage array name.' unless value =~ /\w{1,28}/
    end
  end

  newproperty(:max_queue_depth) do
    desc 'The target port queue depth for all target ports on this array'
    validate do |value|
      raise ArgumentError, 'max-queue-depth must be between 8 and 2048.' unless value.to_i.between?(8, 2048)
    end
  end
end
