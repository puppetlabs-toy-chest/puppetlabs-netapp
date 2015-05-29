require 'puppet/property/netapp_truthy'

Puppet::Type.newtype(:netapp_sis_config) do
  @doc = "Manage Netapp sis config modification."

  apply_to_device

  ensurable

  newparam(:path) do
    desc "The full path of the sis volume, /vol/<vol_name>."
    isnamevar
  end

  newproperty(:enabled, :parent => Puppet::Property::NetappTruthy) do
    truthy_property("Enable sis on a volume.")
  end
  newproperty(:compression, :parent => Puppet::Property::NetappTruthy) do
    truthy_property("Enable compression on the sis volume.")
  end

  #newproperty(:compression_type, :parent => Puppet::Property::NetappTruthy) do
  #  truthy_property("Specifies the compression type on the volume.")
  #end

  newproperty(:inline_compression, :parent => Puppet::Property::NetappTruthy) do
    truthy_property("Enable inline compression on the sis volume.")
  end

  newproperty(:idd, :parent => Puppet::Property::NetappTruthy) do
    truthy_property("Enables file level incompressible data detection and quick check incompressible data detection for large files.")
  end

  newproperty(:quick_check_fsize) do
    desc "Quick check file size for Incompressible Data Detection. Accepts integers"

    newvalues(/^\d+$/)
  end

  newproperty(:policy) do
    desc "The sis policy name to be attached to the volume."
  end

  newproperty(:sis_schedule) do
    desc "The schedule string for the sis operation.
    The format of the schedule:

    day_list[@hour_list] or hour_list[@day_list] or - or auto or manual"
  end

  validate do
    if self[:policy] and self[:sis_schedule]
      raise ArgumentError, "Cannot specify both sis_schedule and policy for a sis config resource"
    end
  end

  autorequire(:netapp_sis_policy) do
    [self[:policy]]
  end

  autorequire(:netapp_volume) do
    [File.basename(self[:path])]
  end
end
