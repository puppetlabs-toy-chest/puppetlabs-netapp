require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_iscsi_security).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netap ISCSI initiator (client) authentication. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :initauthlist    => {:api => 'iscsi-initiator-auth-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :initauthadd    => 'iscsi-initiator-add-auth'
  netapp_commands :initauthdelete => 'iscsi-initiator-delete-auth'

  mk_resource_methods

  def self.instances
    initauths = []
    results = initauthlist() || []
    results.each do |initauth|
      initauth_hash = {
        :name              => initauth.child_get_string('initiator'),
        :ensure            => :present,
        :auth_type         => initauth.child_get_string('auth-type'),
        :radius            => initauth.child_get_string('radius'),
        :username          => initauth.child_get_string('user-name'),
        :outbound_username => initauth.child_get_string('outbound-user-name'),
      }

      initauths << new(initauth_hash)
    end
    initauths
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
      initauthdelete("initiator",resource[:name])
    elsif ! @property_hash.empty?
      initauthdelete("initiator",resource[:name])
      initauthadd(*get_args)
    end
  end

  def create
    initauthadd(*get_args)
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
    args += ['initiator', resource[:name]]
    args += ['auth-type', resource[:auth_type]] if resource[:auth_type]
    args += ['radius', resource[:radius]] if resource[:radius]
    args += ['user-name', resource[:username]] if resource[:username]
    args += ['password', resource[:password]] if resource[:password]
    args += ['outbound-user-name', resource[:outbound_username]] if resource[:outbound_username]
    args += ['outbound-password',  resource[:outbound_password]] if resource[:outbound_password]
    args
  end
end
