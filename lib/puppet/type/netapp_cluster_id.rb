Puppet::Type.newtype(:netapp_cluster_id) do
  @doc = "Manage Netapp Cluster ID."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The cluster name"
    isnamevar

    validate do |value|
      #TODO: Add cluster name validation.
    end
  end

  newproperty(:location) do
    desc "The cluster location"
    isrequired
  end

  newproperty(:contact) do
    desc "The cluster contact"
    isrequired
  end

  # Validate required params
  validate do
    raise ArgumentError, "Location is required" if self[:location].nil?
    raise ArgumentError, "Contact is required" if self[:contact].nil?
  end

end
