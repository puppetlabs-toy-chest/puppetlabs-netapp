require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_cluster_peer).provide(:cmode, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Cluster Peer management."

  confine :feature => :posix
  defaultfor :feature => :posix

  # Restrict to cMode
  confine :true => begin
    a = Puppet::Node::Facts.indirection
    a.terminus_class = :network_device
    a.find(Puppet::Indirector::Request.new(:facts, :find, "clustered", nil))
  rescue
    :false
  end

  netapp_commands :clusterpeerlist => {:api => 'cluster-peer-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :clusterpeeradd  => 'cluster-peer-create'
  netapp_commands :clusterpeermod  => 'cluster-peer-modify'
  netapp_commands :clusterpeerdel  => 'cluster-peer-delete'
  
  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Got to self.instances.")
    peers = []

    # Get a list of peers
    result = clusterpeerlist()

    # Itterate the results
    result.each do |peer|
      peer_name = peer.child_get_string('remote-cluster-name')
      Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Processing remote peer #{peer_name}.")

      # Construct a peer hash
      peer_hash = {
        :name   => peer_name, 
        :ensure => :present
      }

      # Get timeout
      peer_hash[:timeout] = peer.child_get_string('timeout')

      # Process the peer-address array
      peer_addresses = []
      peer.child_get('peer-addresses').children_get().each do |peer_address|
        peer_addresses << peer_address.get_content()
      end
      peer_hash[:peeraddresses] = peer_addresses

      # Create the instance and add to peers array
      Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Creating instance for #{name}, with contents: #{peer_hash.inspect}.")
      peers << new(peer_hash)
    end unless result.nil?

    # Return the final peers array
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Returning peers array")
    peers
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: flushing Netapp Cluster peer #{@resource[:name]}.")

    # Are we updating or destroying? 
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: required resource state = #{@property_hash[:ensure]}")
    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Ensure is absent. Destroying...")

      # Destroy the cluster peer relationship
      clusterpeerdel('cluster-name', @resource[:name])

      # Destroyed...
      Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Destroyed cluster peer relationship with #{@resource[:name]}.")
      return true
    when :present
      Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Ensure is absent. Modifying...")

      # Create a modify request element
      peer_modify = NaElement.new('cluster-peer-modify')

      # Add name and timeout
      peer_modify.child_add_string('cluster-name', @resource[:name])
      peer_modify.child_add_string('timeout', @resource[:timeout])

      # Add peeraddress array
      peeraddresses_element = NaElement.new('peer-addresses')
      @resource[:peeraddresses].each do |peer_address|
        peeraddresses_element.child_add_string('remote-inet-address', peer_address)
      end
      peer_modify.child_add(peeraddresses_element)

      # Modify the cluster peer relationship
      result = clusterpeermod(peer_modify)

      # Modified successfully
      Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Cluster peer relationship with #{@resource[:name]} modified successfully.")
      return true
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: creating Netapp peer relationship with #{@resource[:name]}.")

    # Create a request element
    peer_create = NaElement.new('cluster-peer-create')

    # Add fields
    peer_create.child_add_string('user-name', @resource[:username])
    peer_create.child_add_string('password', @resource[:password])
    peer_create.child_add_string('timeout', @resource[:timeout])

    # Add peeraddresses array
    peeraddresses_element = NaElement.new('peer-addresses')
    @resource[:peeraddresses].each do |peer_address|
      peeraddresses_element.child_add_string('remote-inet-address', peer_address)
    end
    peer_create.child_add(peeraddresses_element)

    # Create the peer relationship
    result = clusterpeeradd(peer_create)

    # Peer relationship created successfully. 
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: Peer relationship with #{@resource[:name]} created successfully.")
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: destroying Netapp peer relationship with #{@resource[:name]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_cluster_peer.cmode: checking existance of Netapp peer relationship with #{@resource[:name]}.")
    @property_hash[:ensure] == :present
  end

end
