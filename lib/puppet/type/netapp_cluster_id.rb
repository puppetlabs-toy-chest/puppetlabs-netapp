Puppet::Type.newtype(:netapp_cluster_id) do
  @doc = "Manage Netapp Cluster ID. [Family: cluster]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The cluster name"
    isnamevar
  end

  newproperty(:location) do
    desc "The cluster location"
  end

  newproperty(:contact) do
    desc "The cluster contact"
  end

end
