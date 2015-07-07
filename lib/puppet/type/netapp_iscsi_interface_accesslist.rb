require 'puppet/parameter/boolean'

Puppet::Type.newtype(:netapp_iscsi_interface_accesslist) do
  @doc = "Create a new association between a Lightweight Directory Access Protocol (LDAP) client configuration and a Vserver. A Vserver can have only one client configuration associated with it."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The name of an existing Lightweight Directory Access Protocol (LDAP) client configuration. The LDAP client configuration can be created using the ldap-client-create API. The ldap-client-get-iter API can be used to retrieve the list of available LDAP client configurations for the cluster."
    isnamevar
  end

  newproperty(:initiator) do
    desc "If true, the corresponding Lightweight Directory Access Protocol (LDAP) configuration is enabled for this Vserver."
  end
end
