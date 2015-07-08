require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_iscsi_interface_accesslist).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp LDAP config"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :iscsiinterfaceaccesslistlist   => {:api => 'iscsi-interface-accesslist-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :iscsiinterfaceaccesslistadd    => 'iscsi-interface-accesslist-add'
  netapp_commands :iscsiinterfaceaccesslistremove => 'iscsi-interface-accesslist-remove'

  mk_resource_methods

  def self.instances
    iscsiinterfaceaccesslists = []
    results = iscsiinterfaceaccesslistlist() || []
    results.each do |iscsiinterfaceaccesslist|
      iscsiinterfaceaccesslist_hash = {
        :name   => "#{iscsiinterfaceaccesslist.child_get_string('interface-name')}/#{iscsiinterfaceaccesslist.child_get_string('initiator')}",
        :ensure => :present,
      }
      iscsiinterfaceaccesslists << new(iscsiinterfaceaccesslist_hash)
    end
    iscsiinterfaceaccesslists
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    case @property_hash[:ensure]
    when :absent
      iscsiinterfaceaccesslistremove(*get_args)
    end
  end

  def create
    iscsiinterfaceaccesslistadd(*get_args)
    @property_hash.clear
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args
    interface_name, initiator = resource[:name].split('/')
    args = Array.new
    args += ['interface-name', interface_name]
    args += ['initiator', initiator]
    args
  end
end
