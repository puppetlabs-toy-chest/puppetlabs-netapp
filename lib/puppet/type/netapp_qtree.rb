require 'puppet/util/network_device'

Puppet::Type.newtype(:netapp_qtree) do
  @doc = "Manage Netapp Qtree creation, modification and deletion. [Family: vserver]"

  apply_to_device

  ensurable

  def self.title_patterns
    [
      [
        %r{^([^/].+)$},
        [
          [:qtname],
        ]
      ],
      [
        %r{^/([^/]+)/(.+)$},
        [
          [:volume],
          [:qtname],
        ]
      ]
    ]
  end

  newparam(:qtname, :namevar => true) do
    desc "The qtname to create."
    validate do |value|
      unless value =~ /^[\w\-\.]+$/
         raise ArgumentError, "%s is not a valid qtree name." % value
      end
    end
  end

  newparam(:volume, :namevar => true) do
    desc "The volume to create qtree against."
    validate do |value|
      unless value =~ /^\w+$/
         raise ArgumentError, "%s is not a valid volume name." % value
      end
    end
  end

  newproperty(:exportpolicy) do
    desc "The export policy with which the qtree is associated."
  end

  autorequire(:netapp_volume) do
    self[:volume]
  end
  autorequire(:netapp_export_policy) do
    self[:exportpolicy]
  end
end
