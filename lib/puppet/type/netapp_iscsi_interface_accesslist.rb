require 'puppet/parameter/boolean'

Puppet::Type.newtype(:netapp_iscsi_interface_accesslist) do
  @doc = "Add / Remove the iSCSI LIFs to the accesslist of the specified initiator. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "iSCSI LIF Name and Initiator that can access the iSCSI LIFs. Separated by a / 
    eg iscsilif/iqn.1995-08.com.example:string"
    isnamevar
  end
end
