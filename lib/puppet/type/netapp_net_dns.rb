require 'resolv'

Puppet::Type.newtype(:netapp_net_dns) do
  @doc = 'Manage Netapp DNS server mapping. [Family: vserver]'

  apply_to_device

  ensurable

  newparam(:name) do
    desc 'vserver name'
    isnamevar
    validate do |value|
      raise ArgumentError, 'A Vserver name can only contain alphanumeric characters and ".", "-" or "_"' unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:domains, :array_matching => :all) do
    desc 'Domain for the Vserver.'
    def insync?(is)
      is = [] if is == :absent
      @should.sort == is.sort
    end
  end

  newproperty(:name_servers, :array_matching => :all) do
    desc 'IPv4 addresses of name servers.'
    validate do |value|
      raise ArgumentError, '#{value} is an invalid value for field "name-servers"' unless value =~ Resolv::IPv4::Regex
    end
    def insync?(is)
      is = [] if is == :absent
      @should.sort == is.sort
    end
  end

  newproperty(:state) do
    desc 'The state of the DNS server mapping'
    newvalues(:enabled, :disabled)
  end
end
