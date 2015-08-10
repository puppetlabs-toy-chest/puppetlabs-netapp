require 'ipaddr'

Puppet::Type.newtype(:netapp_vserver_peer) do
  @doc = "Manage Netapp Vserver Peering."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The local vserver name. and peer_vserver eg vs0:vs1"
    isnamevar
  end

  newproperty(:peer_cluster) do
    desc "Specifies name of the peer Cluster. If peer Cluster is not given, it considers local Cluster."
  end

  newproperty(:applications, :array_matching => :all) do
    desc "Applications which can make use of the peering relationship. Possible values: 'snapmirror', 'file_copy', 'lun_copy'."
    def insync?(is)
      is = [] if is == :absent
      @should.sort == is.sort
    end
  end
end
