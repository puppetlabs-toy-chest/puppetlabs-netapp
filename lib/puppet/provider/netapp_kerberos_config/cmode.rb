require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_kerberos_config).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp kerberos config. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :kerberosconfiglist     => {:api => 'kerberos-config-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :kerberosconfigmodify   => 'kerberos-config-modify'

  mk_resource_methods

  def self.instances
    kerberosconfigs = []
    results = kerberosconfiglist() || []
    results.each do |kerberosconfig|
      kerberosconfig_hash = {
        :name                   => kerberosconfig.child_get_string('interface-name'),
        :admin_password         => kerberosconfig.child_get_string('admin-password'),
        :admin_user_name        => kerberosconfig.child_get_string('admin-user-name'),
        :force                  => kerberosconfig.child_get_string('force'),
        :is_kerberos_enabled    => kerberosconfig.child_get_string('is-kerberos-enabled'),
        :keytab_uri             => kerberosconfig.child_get_string('keytab-uri'),
        :organizational_unit    => kerberosconfig.child_get_string('organizational-unit'),
        :service_principal_name => kerberosconfig.child_get_string('service-principal-name'),
        :ensure                 => :present,
      }
      kerberosconfigs << new(kerberosconfig_hash)
    end
    kerberosconfigs
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
    when :present
      kerberosconfigmodify(*get_args)
    end
  end

  def create
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
    args += ['interface-name', resource[:name]]
    args += ['admin-password', resource[:admin_password]] unless @resource[:admin_password].nil?
    args += ['admin-user-name', resource[:admin_user_name]] unless @resource[:admin_user_name].nil?
    args += ['force', resource[:force]] unless @resource[:force].nil?
    args += ['is-kerberos-enabled', resource[:is_kerberos_enabled]] unless @resource[:is_kerberos_enabled].nil?
    args += ['keytab-uri', resource[:keytab_uri]] unless @resource[:keytab_uri].nil?
    args += ['organizational-unit', resource[:organizational_unit]] unless @resource[:organizational_unit].nil?
    args += ['service-principal-name', resource[:service_principal_name]] unless @resource[:service_principal_name].nil?
    args
  end
end
