Puppet::Type.newtype(:netapp_ldap_client) do
  @doc = "Manage Netapp LDAP client configuration for the cluster. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The name of the LDAP client configuration."
    isnamevar
    validate do |value|
      raise ArgumentError, '#{value} is an invalid LDAP client configuration name.' unless value =~ /\w{1,32}/
    end
  end

  newproperty(:ad_domain) do
    desc "The Active Directory Domain Name for this LDAP configuration. The option is ONLY applicable for configurations using Active Directory LDAP servers.The Active Directory Domain Name for this LDAP configuration. The option is ONLY applicable for configurations using Active Directory LDAP servers."
  end
  
  newproperty(:allow_ssl, :boolean => true) do
    desc "Allows the use of SSL for the TLS Handshake Protocol over the LDAP connections. The default value is false."
    newvalues(:true, :false)
  end

  newproperty(:base_dn) do
    desc "Indicates the starting point for searches within the LDAP directory tree. If omitted, searches will start at the root of the directory tree."
  end

  newproperty(:base_scope) do
    desc "This indicates the scope for LDAP search. If omitted, this parameter defaults to 'subtree'. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates"
    newvalues(:base, :onelevel, :subtree)
    defaultto(:subtree)
  end

  newproperty(:bind_as_cifs_server, :boolean => true) do
    desc "If set, the cluster will use the CIFS server's credentials to bind to the LDAP server. If omitted, this parameter defaults to 'true' if the configuration uses Active Directory LDAP and defaults to 'false' otherwise."
    newvalues(:true, :false)
    defaultto(:false)
  end

  newproperty(:bind_dn) do
    desc "The Bind Distinguished Name (DN) is the LDAP identity used during the authentication process by the clients. This is required if the LDAP server does not support anonymous binds. This field is not used if 'bind-as-cfs-server' is set to 'true'. Example : cn=username,cn=Users,dc=example,dc=com"
  end

  newproperty(:bind_password) do
    desc "The password to be used with the bind-dn."
  end

  newproperty(:group_dn) do
    desc "The Group Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for group lookups. If not specified, group lookups will start at the base-dn."
  end

  newproperty(:group_scope) do
    desc "This indicates the scope for LDAP search when doing group lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates"
    newvalues(:base, :onelevel, :subtree)
  end

  newproperty(:is_netgroup_byhost_enabled, :boolean => true) do
    desc "This indicates whether netgroup.byhost map should be queried for lookups."
    newvalues(:true, :false)
    defaultto(:false)
  end

  newproperty(:min_bind_level) do
    desc "The minimum authentication level that can be used to authenticate with the LDAP server. If omitted, this parameter defaults to 'sasl'. Possible values:
anonymous - Anonymous bind,
simple - Simple bind,
sasl - Simple Authentication and Security Layer (SASL) bind"
    newvalues(:anonymous, :simple, :sasl)
    defaultto(:sasl)
  end

  newproperty(:netgroup_byhost_dn) do
    desc "The Netgroup Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for netgroup byhost lookups. If not specified, netgroup byhost lookups will start at the base-dn."
  end

  newproperty(:netgroup_byhost_scope) do
    desc "This indicates the scope for LDAP search when doing netgroup byhost lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates"
    newvalues(:base, :onelevel, :subtree)
  end

  newproperty(:netgroup_dn) do
    desc "The Netgroup Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for netgroup lookups. If not specified, netgroup lookups will start at the base-dn."
  end

  newproperty(:netgroup_scope) do
    desc "This indicates the scope for LDAP search when doing netgroup lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates"
    newvalues(:base, :onelevel, :subtree)
  end

  newproperty(:preffered_ad_servers, :array_matching => :all) do
    desc "Preferred Active Directory (AD) Domain controllers to use for this configuration. This option is ONLY applicable for configurations using Active Directory LDAP servers"
    def insync?(is)
      is = [] if is == :absent
      @should.sort == is.sort
    end
  end

  newproperty(:query_timeout) do
    desc "Maximum time in seconds to wait for a query response from the LDAP server. The default for this parameter is 3 seconds."
    defaultto(3)
  end

  newproperty(:schema) do
    desc "LDAP schema to use for this configuration."
  end

  newproperty(:servers, :array_matching => :all) do
    desc "List of LDAP Server IP addresses to use for this configuration. The option is NOT applicable for configurations using Active Directory LDAP servers."
    def insync?(is)
      is = [] if is == :absent
      @should.sort == is.sort
    end
 end

   newproperty(:tcp_port) do
    desc "The TCP port on the LDAP server to use for this configuration. If omitted, this parameter defaults to 389."
    defaultto(389)
  end

  newproperty(:use_start_tls) do
    desc "This indicates if start_tls will be used over LDAP connections."
  end

  newproperty(:user_dn) do
    desc "The User Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for user lookups. If this parameter is omitted, user lookups will start at the base-dn."
  end

  newproperty(:user_scope) do
    desc "This indicates the scope for LDAP search when doing user lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates"
    newvalues(:base, :onelevel, :subtree)
  end
end
