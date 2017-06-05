require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_cluster_id).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Cluster ID management. [Family: cluster]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :clusteridget => 'cluster-identity-get'
  netapp_commands :clusteridmod => 'cluster-identity-modify'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_cluster_id.cmode self.instances: Got to self.instances.")

    clusters = []

    # Get the cluster ID
    result = clusteridget()

    if result
      #Puppet.debug("Result looks like #{result.sprintf()}")
      # Pull out relevant fields
      cluster_id = result.child_get('attributes').child_get('cluster-identity-info')
      cluster_name = cluster_id.child_get_string('cluster-name')
      cluster_location = cluster_id.child_get_string('cluster-location')
      cluster_contact = cluster_id.child_get_string('cluster-contact')

      # Construct the cluster_info hash
      cluster_info = {
        :name => cluster_name,
        :ensure => :present,
        :location => cluster_location,
        :contact => cluster_contact
      }

      Puppet.debug("Puppet::Provider::Netapp_cluster_id.cmode self.instances: cluster_info = #{cluster_info}.")
      clusters << new(cluster_info)
    end

    clusters
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_cluster_id.cMode: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_cluster_id.cMode: Got to flush for resource #{@resource[:name]}.")

    # Update cluster ID details
    result = clusteridmod('cluster-name', @resource[:name], 'cluster-location', @resource[:location], 'cluster-contact', @resource[:contact])

  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_cluster_id.cmode create: Nothing to create....")
    fail('Cluster_id create not supported, and no matching existing cluster found.')
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_cluster_id.cmode: Nothing to destroy...")
    notice('Destroy not supported.')
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_cluster_id.cmode exists?: checking existance of Netapp Cluster ID #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end

end
