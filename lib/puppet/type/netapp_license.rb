Puppet::Type.newtype(:netapp_license) do
  @doc = "Manage Netapp Licenses. Only supported by ONTAP 8.2 and newer."

  apply_to_device

  ensurable

  newparam(:code) do
    desc "The license code"
    isnamevar
  end

end
