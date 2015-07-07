require 'puppet/parameter/boolean'

Puppet::Type.newtype(:netapp_options) do
  @doc = "System configuration option" 

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The name of the option" 
    isnamevar
  end

  newproperty(:value) do
    desc "If true, the corresponding Lightweight Directory Access Protocol (LDAP) configuration is enabled for this Vserver."
  end
end
