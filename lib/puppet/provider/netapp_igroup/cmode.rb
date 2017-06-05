require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_igroup).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp initiator groups. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :igrouplist          => {:api => 'igroup-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :igroupcreate        => 'igroup-create'
  netapp_commands :igroupdestroy       => 'igroup-destroy'
  netapp_commands :igroupadd           => 'igroup-add'
  netapp_commands :igroupremove        => 'igroup-remove'
  netapp_commands :igroupportsetbind   => 'igroup-bind-portset'
  netapp_commands :igroupportsetunbind => 'igroup-unbind-portset'
  netapp_commands :igroupsetattribute  => 'igroup-set-attribute'

  mk_resource_methods

  def self.instances
    igroups = []
    results = igrouplist() || []
    results.each do |igroup|
      if initiators = igroup.child_get('initiators')
        members = initiators.children_get.collect do |initiator|
          initiator.child_get_string('initiator-name')
        end
      end
      igroup_hash = {
        :name       => igroup.child_get_string('initiator-group-name'),
        :ensure     => :present,
        :group_type => igroup.child_get_string('initiator-group-type'),
        :os_type    => igroup.child_get_string('initiator-group-os-type'),
        :portset    => igroup.child_get_string('initiator-group-portset-name') || "false",
        :members    => members
      }
      igroups << new(igroup_hash)
    end
    igroups
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def create
    igroupcreate(*get_args)
    members = resource[:members]
    @property_hash.clear
  end

  def os_type=(value)
    igroupsetattribute('initiator-group-name',resource[:name],'attribute','os-type','value',value)
  end

  def portset=(value)
    if value == "false"
      igroupportsetunbind('initiator-group-name', resource[:name])
    else
      igroupportsetbind('initiator-group-name',resource[:name],'portset-name',value)
    end
  end

  def group_type=(value)
    raise ArgumentError, "group_type cannot be changed after creation"
  end

  def members=(value)
    to_remove = (@original_values[:members] || []) - value
    to_add = value - (@original_values[:members] || [])

    to_remove.each do |member|
      force
      if @resource[:force] == nil
        force = false
      else
        force = @resource[:force]
      end
      igroupremove('initiator-group-name',resource[:name],'initiator',member,'force',force)
    end
    to_add.each do |member|
      igroupadd('initiator-group-name',resource[:name],'initiator',member)
    end
  end

  def destroy
    igroupdestroy('initiator-group-name',resource[:name])
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args
    args = Array.new
    args += ['initiator-group-name', resource[:name]]
    args += ['initiator-group-type', resource[:group_type]] if resource[:group_type]
    args += ['os-type', resource[:os_type]] if resource[:os_type]
    args += ['bind-portset', resource[:portset]] if resource[:portset]
    args
  end
end
