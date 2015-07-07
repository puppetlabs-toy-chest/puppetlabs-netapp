require 'puppet/parameter/boolean'

Puppet::Type.newtype(:netapp_kerberos_config) do
  @doc = "Kerberos configuration information for a LIF"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "Logical interface."
    isnamevar
  end

  newproperty(:admin_password) do
    desc "Administrator password for the Key Distribution Center"
  end

  newproperty(:admin_user_name) do
    desc "Administrator password for the Key Distribution Center"
  end

  newproperty(:force) do
    desc "Force option to disable Kerberos security on a LIF (default:false). If set to true, any errors encountered when deleting the corresponding account on the KDC are ignored in which case the account should be deleted manually."
  end

  newproperty(:is_kerberos_enabled, :boolean => true) do
    desc "If 'true', Kerberos security is enabled by creating an account in the Key Distribution Center using the Service Principal Name. If another logical interface uses the same Service Principal Name, the account is shared.
If 'false', Kerberos security is disabled and the associated account is deleted when it is not used by any logical interface. Attributes: non-creatable, modifiable"
    newvalues(:true, :false)
    defaultto(:false)
  end 

  newproperty(:keytab_uri) do
    desc "Load Keytab from URI. This field should not be specified when disabling Kerberos."
  end

  newproperty(:organizaational_unit) do
    desc "Organization Unit. This option is available for a Microsoft AD KDC only."
  end

  newproperty(:service_principal_name) do
    desc "Kerberos service principal name. This is a required input for enabling Kerberos. This input should not be specified when disabling Kerberos. "
  end
end
