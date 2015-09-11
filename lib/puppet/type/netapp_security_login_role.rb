Puppet::Type.newtype(:netapp_security_login_role) do
  @doc = "A login role [Family: cluster]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "A composite key made up from command_directory_name:role_name:vserver eg ssh:password:vsadmin:vserver01"
    isnamevar
  end

  newproperty(:access_level) do
    desc "Access level for the role. Possible values: 'none', 'readonly', 'all'. The default value is 'all'."
  end

  newproperty(:role_query) do
    desc "A query for the role. The query must apply to the specified command or directory name. Example: The command is 'volume show' and the query is '-volume vol1'. The query is applied to the command resulting in populating only the volumes with name vol1."
  end
end
