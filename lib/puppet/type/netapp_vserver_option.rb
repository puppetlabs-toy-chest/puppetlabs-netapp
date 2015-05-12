Puppet::Type.newtype(:netapp_vserver_option) do
  @doc = "Manage Netapp Vserver option modification."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The vserver option name"
    isnamevar

    validate do |value|
      raise ArgumentError, "#{value} is an invalid option name format." unless value =~ /((?:[\w_]*.?){2,3})/
    end
  end

  newproperty(:value) do
    desc "The vserver option value"

    validate do |value|
      raise ArgumentError, "#{value} is an invalid option value." unless value =~ /\w*/
    end
  end

end
