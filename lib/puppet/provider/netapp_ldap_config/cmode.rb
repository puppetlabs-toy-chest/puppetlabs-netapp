require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_ldap_config).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp LDAP config. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :ldapconfiglist     => {:api => 'ldap-config-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :ldapconfigcreate   => 'ldap-config-create'
  netapp_commands :ldapconfigdestroy  => 'ldap-config-delete'
  netapp_commands :ldapconfigmodify   => 'ldap-config-modify'

  mk_resource_methods

  def self.instances
    ldapconfigs = []
    results = ldapconfiglist() || []
    results.each do |ldapconfig|
      ldapconfig_hash = {
        :name           => ldapconfig.child_get_string('client-config'),
        :client_enabled => ldapconfig.child_get_string('client-enabled'),
        :ensure         => :present,
      }
      ldapconfigs << new(ldapconfig_hash)
    end
    ldapconfigs
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
      ldapconfigdestroy()
    when :present
      ldapconfigmodify(*get_args)
    end
  end

  def create
    ldapconfigcreate(*get_args)
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
    args += ['client-config', resource[:name]]
    args += ['client-enabled', resource[:client_enabled]]
    args
  end
end
