require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_kerberos_realm).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp kerberos realm. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :kerberosrealmlist    => {:api => 'kerberos-realm-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :kerberosrealmcreate  => 'kerberos-realm-create'
  netapp_commands :kerberosrealmdestroy => 'kerberos-realm-delete'
  netapp_commands :kerberosrealmmodify  => 'kerberos-realm-modify'

  mk_resource_methods

  def self.instances
    kerberosrealms = []
    results = kerberosrealmlist() || []
    results.each do |kerberosrealm|
      kerberosrealm_hash = {
        :name                 => kerberosrealm.child_get_string('realm'),
        :ad_server_ip         => kerberosrealm.child_get_string('ad-server-ip'),
        :ad_server_name       => kerberosrealm.child_get_string('ad-server-name'),
        :admin_server_ip      => kerberosrealm.child_get_string('admin-server-ip'),
        :admin_server_port    => kerberosrealm.child_get_string('admin-server-port'),
        :clock_skew           => kerberosrealm.child_get_string('clock-skew'),
        :comment              => kerberosrealm.child_get_string('comment'),
        :config_name          => kerberosrealm.child_get_string('config-name'),
        :kdc_ip               => kerberosrealm.child_get_string('kdc-ip'),
        :kdc_port             => kerberosrealm.child_get_string('kdc-port'),
        :kdc_vendor           => kerberosrealm.child_get_string('kdc-vendor'),
        :password_server_ip   => kerberosrealm.child_get_string('password-server-ip'),
        :password_server_port => kerberosrealm.child_get_string('password-server-port'),
        :ensure               => :present,
      }
      kerberosrealms << new(kerberosrealm_hash)
    end
    kerberosrealms
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
      kerberosrealmdestroy('realm',resource[:name])
    when :present
      kerberosrealmmodify(*get_args)
    end
  end

  def create
    kerberosrealmcreate(*get_args)
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
    args += ['realm', resource[:name]]
    args += ['ad-server-ip', resource[:ad_server_ip]] unless resource[:ad_server_ip].nil?
    args += ['ad-server-name', resource[:ad_server_name]] unless resource[:ad_server_name].nil?
    args += ['admin-server-ip', resource[:admin_server_ip]]
    args += ['admin-server-port', resource[:admin_server_port]]
    args += ['clock-skew', resource[:clock_skew]]
    args += ['comment', resource[:comment]] unless resource[:comment].nil?
    args += ['config-name', resource[:config_name]] unless resource[:config_name].nil?
    args += ['kdc-ip', resource[:kdc_ip]]
    args += ['kdc-port', resource[:kdc_port]]
    args += ['kdc-vendor', resource[:kdc_vendor]]
    args += ['password-server-ip', resource[:password_server_ip]]
    args += ['password-server-port', resource[:password_server_port]]
    args
  end
end
