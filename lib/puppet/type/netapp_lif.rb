require 'ipaddr'

Puppet::Type.newtype(:netapp_lif) do
  @doc = "Manage Netapp Logical Inteface (LIF) creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:interfacename) do
    desc "LIF name"
    isnamevar

    validate do |value|
      raise ArgumentError, "#{value} format is invalid" unless value =~ /\w*/
    end
  end

  newproperty(:address) do
    desc "LIF IP address"

    validate do |value|
      begin
        ip = IPAddr.new(value)
      rescue ArgumentError
        raise ArgumentError, "#{value} is not a vaild IP address"
      end
    end
  end

  newproperty(:administrativestatus) do
    desc "LIF administratative status. Defaults to: 'up'. Possible values: 'up', 'down'."
    newvalues(:up, :down)
    defaultto(:up)
  end

  newproperty(:comment) do
    desc "LIF comment"
  end

  newparam(:dataprotocols, :array_matching => :all) do
    desc "LIF data protocols. Possible values: 'nfs', 'cifs', 'iscsi', 'fcp', 'fcache', 'none'"
    newvalues(:nfs, :cifs, :iscsi, :fcp, :fcache, :none)
  end

  newproperty(:dnsdomainname) do
    desc "LIF dns domain name."
    validate do |value|
      #TODO: Validate that the Domain name format is correct
    end
  end

  newproperty(:failovergroup) do
    desc "LIF failover group name"
  end

  newproperty(:failoverpolicy) do
    desc "LIF failover policy. Defaults to: 'nextavail'. Possible values: 'nextavail', 'priority', 'disabled'."
    newvalues(:nextavail, :priority, :disabled)
    defaultto(:nextavail)
  end

  newproperty(:firewallpolicy) do
    desc "LIF firewall policy. Default is based on the port role. Possible values: 'mgmt', 'cluster', 'intercluster'."
    newvalues(:mgmt, :cluster, :intercluster)
  end

  newproperty(:homenode) do
    desc "LIF home node."
  end

  newproperty(:homeport) do
    desc "LIF home port."
  end

  newproperty(:isautorevert) do
    desc "Should the LIF revert to it's home node. Defaults to: false."
    newvalues(:true, :false)
    defaultto(:false)
  end

  newproperty(:netmask) do
    desc "LIF netmask."
    validate do |value|
      unless value =~ /(?:\d{1,3})\.(?:\d{1,3})\.(?:\d{1,3})\.(?:\d{1,3})/
        raise ArgumentError, "#{value} is not a valid netmask."
      end
    end
  end

  newproperty(:netmasklength) do
    desc "LIF netmask length"
    validate do |value|
      begin
        netmask = IPAddr.new('255.255.255.255').mask(value)
      rescue ArgumentError
        raise ArgumentError, "#{value} is not a valid CIDR."
      end
      # TODO: Validate netmask length
    end
  end

  newparam(:role) do
    desc "LIF Role. Defaults to: 'data'. Possible values: 'undef', 'cluster', 'data', 'node_mgmt', 'intercluster', 'cluster_mgmt'."
    newvalues(:undef, :cluster, :data, :node_mgmt, :intercluster, :cluster_mgmt)
    defaultto(:data)
  end

  newproperty(:routinggroupname) do
    desc "LIF Routing group. Valid format is [dcn][ip address]/[subnet]."
    validate do |value|
      unless value =~ /[dcn](?:\d{1,3})\.(?:\d{1,3})\.(?:\d{1,3})\.(?:\d{1,3})\/\d{1,2}/
        raise ArgumentError, "%s is not a valid routing group name." % value
      end
    end
  end

  newproperty(:usefailovergroup) do
    desc "Should failover group be automatically created? Defaults to: 'disabled'. Possible values: 'system_defined', 'disabled', 'enabled'."
    newvalues(:disabled, :enabled, :system_defined)
    defaultto(:disabled)
  end

  newparam(:vserver) do
    desc "LIF Vserver name"
  end


  # Validate input values
  validate do
    if Array(self[:dataprotocols]).include?('none') and Array(self[:dataprotocols]).length > 1
      raise ArgumentError, "'none' cannot be combined with other data protocols."
    end
    raise ArgumentError, "Address is required" if (self[:address] || self.provider.address).nil?
    raise ArgumentError, "Vserver is required" if (self[:vserver] || self.provider.vserver).nil?
    raise ArgumentError, "Netmask or Netmasklength are required" if (self[:netmask] || self.provider.netmask).nil? and (self[:netmasklength] || self.provider.netmasklength).nil?
    raise ArgumentError, "Netmask and Netmasklength are mutually exclusive" if self[:netmask] and self[:netmasklength]
    #XXX homenode, homeport, role?, vserver, interface-name, address are required
  end


  # Autorequire appropriate resources
  autorequire(:netapp_vserver) do
    self[:vserver]
  end
end
