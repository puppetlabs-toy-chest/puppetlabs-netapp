Puppet::Type.newtype(:netapp_security_login) do
  @doc = "A user account associated with the specified application and authentication method. A new user account can be created with user name as the Active Directory group name. This user account gives access to users belonging to the specified Active Directory group. [Family: cluster]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "A composite key made up from application:authentication_method:username:vserver eg ssh:password:vsadmin:vserver01"
    isnamevar
  end

  newparam(:password) do
    desc "Password for the user account. This is ignored for creating snmp users. This is required for creating non-snmp users."
  end

  newproperty(:comment) do
    desc "Comments for the user account. The length of comment should be less than or equal to 128 charaters."
  end

  newproperty(:role_name) do
    desc "The default value is 'admin' for Admin vserver and 'vsadmin' for data vserver. This field is required."
  end

  newproperty(:is_locked) do
    desc "Whether the login is locked, The valid values for are true or false"
  end

  validate do
    if self[:ensure] == :present and ! self[:role_name]
      raise ArgumentError, "role_name is required"
    end
  end
end
