require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_nfs).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp nfs service"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :nfslist    => {:api => 'nfs-service-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :nfscreate  => 'nfs-service-create'
  netapp_commands :nfsdestroy => 'nfs-service-destroy'
  netapp_commands :nfsmodify  => 'nfs-service-modify'
  netapp_commands :nfsenable  => 'nfs-enable'
  netapp_commands :nfsdisable => 'nfs-disable'

  mk_resource_methods

  def self.instances
    nfss = []
    results = nfslist() || []
    results.each do |nfs|
      vserver = nfs.child_get_string('vserver')
      nfs_hash = {
        :name   => vserver,
        :ensure => :present,
        :v3     => nfs.child_get_string('is-nfsv3-enabled') == 'true' ? 'enabled' : 'disabled',
        :v40    => nfs.child_get_string('is-nfsv40-enabled') == 'true' ? 'enabled' : 'disabled',
        :v41    => nfs.child_get_string('is-nfsv41-enabled') == 'true' ? 'enabled' : 'disabled',
      }

      nfs_state = nfs.child_get_string('is-nfs-access-enabled')
      if nfs_state == 'true'
        nfs_hash[:state] = 'on'
      else
        nfs_hash[:state] = 'off'
      end

      nfss << new(nfs_hash)
    end
    nfss
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_hash[:ensure] == :absent
      nfsdestroy()
    elsif ! @property_hash.empty?
      nfsmodify(*get_args)
    end
  end

  def state=(value)
    case resource[:state]
    when :on
      nfsenable()
    when :off
      nfsdisable()
    end
  end

  def create
    nfscreate(*get_args)
    @property_hash.clear
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args
    args = Array.new
    args += ['is-nfsv3-enabled', resource[:v3] == :enabled ? 'true' : 'false'] if resource[:v3]
    args += ['is-nfsv40-enabled', resource[:v40] == :enabled ? 'true' : 'false'] if resource[:v40]
    args += ['is-nfsv41-enabled', resource[:v41] == :enabled ? 'true' : 'false'] if resource[:v41]
    args
  end
end
