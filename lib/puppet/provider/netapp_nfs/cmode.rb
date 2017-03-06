require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_nfs).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp nfs service. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :nfslist        => {:api => 'nfs-service-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :nfscreate     => 'nfs-service-create'
  netapp_commands :nfsdestroy    => 'nfs-service-destroy'
  netapp_commands :nfsmodify     => 'nfs-service-modify'
  netapp_commands :nfsenable     => 'nfs-enable'
  netapp_commands :nfsdisable    => 'nfs-disable'
  mk_resource_methods

  def self.instances
    nfss = []
    results = nfslist() || []
    results.each do |nfs|
      vserver = nfs.child_get_string('vserver')
      nfs_hash = {
        :name                => vserver,
        :ensure              => :present,
        :v3                  => nfs.child_get_string('is-nfsv3-enabled') == 'true' ? 'enabled' : 'disabled',
        :v40                 => nfs.child_get_string('is-nfsv40-enabled') == 'true' ? 'enabled' : 'disabled',
        :v41                 => nfs.child_get_string('is-nfsv41-enabled') == 'true' ? 'enabled' : 'disabled',
        :showmount           => nfs.child_get_string('showmount') == 'true' ? 'enabled' : 'disabled',
        :v3msdosclient       => nfs.child_get_string('is-v3-ms-dos-client-enabled') == 'true' ? 'enabled' : 'disabled',
        :v364bitidentifiers  => nfs.child_get_string('is-nfsv3-64bit-identifiers-enabled') == 'true' ? 'enabled' : 'disabled',
        :v41pnfs             => nfs.child_get_string('is-nfsv41-pnfs-enabled') == 'true' ? 'enabled' : 'disabled',
        :v41referrals        => nfs.child_get_string('is-nfsv41-referrals-enabled') == 'true' ? 'enabled' : 'disabled',
        :nfsv4iddomain       => nfs.child_get_string('nfsv4-id-domain'),
        :v4numericids        => nfs.child_get_string('is-nfsv4-numeric-ids-enabled') == 'true' ? 'enabled' : 'disabled',
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
    args += ['showmount', resource[:showmount] == :enabled ? 'true' : 'false'] if resource[:showmount]
    args += ['is-v3-ms-dos-client-enabled', resource[:v3msdosclient] == :enabled ? 'true' : 'false'] if resource[:v3msdosclient]
    args += ['is-nfsv3-64bit-identifiers-enabled', resource[:v364bitidentifiers] == :enabled ? 'true' : 'false'] if resource[:v364bitidentifiers]
    args += ['is-nfsv41-pnfs-enabled', resource[:v41pnfs] == :enabled ? 'true' : 'false'] if resource[:v41pnfs]
    args += ['is-nfsv41-referrals-enabled', resource[:v41referrals] == :enabled ? 'true' : 'false'] if resource[:v41referrals]
    args += ['is-nfsv4-numeric-ids-enabled', resource[:v4numericids] == :enabled ? 'true' : 'false'] if resource[:v4numericids]
    args += ['nfsv4-id-domain', resource[:nfsv4iddomain]] 
    args
  end
end
