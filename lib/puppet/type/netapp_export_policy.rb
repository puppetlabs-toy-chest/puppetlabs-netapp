Puppet::Type.newtype(:netapp_export_policy) do
  @doc = "Manage Netapp CMode Export Policy creation and deletion. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The export policy name."
    isnamevar
  end
end
