Puppet::Type.newtype(:netapp_lun) do
  @doc = "Manage Netap Lun creation, modification and deletion. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:path) do
    desc "Lun path"
    isnamevar
  end

  newproperty(:size) do
    desc "Lun size. Can either be specified in bytes, or specify one of the following size units: [mgt]."

    validate do |value|
      raise ArgumentError, "Value must either be in bytes, or specify a size unit." unless value =~ /\d+[mgt]?/
    end

    munge do |value|
      if value =~ /\d+[mgt]/
        # Convert from size unit to bytes
        if value.include?('t')
          value = value.gsub(/t/, '').to_i*1024*1024*1024*1024
        elsif value.include?('g')
          value = value.gsub(/g/, '').to_i*1024*1024*1024
        elsif value.include?('m')
          value = value.gsub(/m/, '').to_i*1024*1024
        end
      end
      value
    end
  end

  newproperty(:state) do
    desc "Lun state. Default value: 'online'. Possible values: 'online', 'offline'."
    newvalues(:online, :offline)
    defaultto(:online)
  end

  newproperty(:force) do
    desc "Forcibly reduce the size. This is required for reducing the size of the LUN to avoid accidentally reducing the LUN size. Default to false"
    newvalues(:false, :true)
  end

  newparam(:lunclass) do
    desc "Lun class. Default value = 'regular'. Possible values: 'regular', 'protectedendpoint', 'vvol'."
    newvalues(:regular, :protectedendpoint, :vvol)
    defaultto(:regular)
  end

  newparam(:ostype) do
    desc "Lun OS Type. Defaults to 'image'. Possible values: 'image', 'aix', 'hpux', 'hyper_v', 'linux', 'netware', 'openvms',
    'solaris', 'solaris_efi', 'vmware', 'windows', 'windows_2008', 'windows_gpt'"
    newvalues(:image, :aix, :hpux, :hyper_v, :linux, :netware, :openvms, :solaris, :solaris_efi, :vmware, :windows, :windows_2008, :windows_gpt)
    defaultto(:image)
  end

  newparam(:prefixsize) do
    desc "Lun prefix stream size in bytes. Default value is based on ostype. Not required for 'image' ostype. Must be a multiple of 512 bytes."

    validate do |value|
      # TODO: Must devide by 512 bytes.
      raise ArgumentError, 'Prefixsize must divide by 512' unless value.to_i % 512 == 0
    end
  end

  newparam(:qospolicygroup) do
    desc "QOS Policy group"
  end

  newparam(:spaceresenabled) do
    desc "Enable Lun space reservation? Defaults to true."
    newvalues(:true, :false)
    defaultto(:true)
  end


  ## Validate params
  validate do
    raise ArgumentError, 'Prefixsize is not required for \'image\' ostype.' if self[:ostype] == :image and !self[:prefixsize].nil?
  end

  ## Autorequire resources
  # Netapp_volume resources
  autorequire(:netapp_volume) do
    requires = []

    # Extract volume from path
    if match = %r{/\w+/(\w+)(?:/\w+)?$}.match(self[:path])
      requires << match.captures[0]
    end

    requires
  end

  # Netapp_qtree resources
  autorequire(:netapp_qtree) do
    requires = []

    # Extract qtree from path
    if match = %r{/\w+/\w+/(\w+)(?:/\w+)+$}.match(self[:path])
      requires << match.captures[0] if match.captures[0]
    end

    requires
  end

end
