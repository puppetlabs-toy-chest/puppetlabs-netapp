require 'ipaddr'

Puppet::Type.newtype(:netapp_cluster_peer) do
  @doc = "Manage Netapp Cluster Peering."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The cluster peer name. Must match the remote cluster name."
    isnamevar
  end

  newproperty(:peeraddresses, :array_matching => :all) do
    desc "Cluster peer address array"

    validate do |value|
      begin
        valid = IPAddr.new(value)
      rescue ArgumentError
        raise ArgumentError, "#{value} is an invalid IP address"
      end
    end

    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # If they were different lengths, they are not equal.
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

  newparam(:username) do
    desc "Cluster peer username."

    validate do |value|
      raise ArgumentError, "#{value} is an invalid username" unless value =~ /\w*/
    end
  end

  newparam(:password) do
    desc "Cluster peer password."

    validate do |value|
      raise ArgumentError, "#{value} is an invalid password" unless value =~ /\w*/
    end
  end

  newproperty(:timeout) do
    desc "Cluster operation timeout. Must be between 25 and 180. Defaults to: 25."
    defaultto('25')

    validate do |value|
      raise ArgumentError, "#{value} must be between 0 and 180" unless value.to_i.between?(25,180)
    end
  end

  # Validate required params
  validate do
    raise ArgumentError, "Peer address must be an array." unless self[:peeraddresses].is_a?Array
    raise ArgumentError, "Username is required." if self[:username].nil?
    raise ArgumentError, "Password is required." if self[:password].nil?
  end

end
