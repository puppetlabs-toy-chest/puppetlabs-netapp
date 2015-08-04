require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_security_login).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp security logins"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :securityloginlist    => {:api => 'security-login-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :securitylogincreate  => 'security-login-create'
  netapp_commands :securitylogindestroy => 'security-login-delete'
  netapp_commands :securityloginmodify  => 'security-login-modify'
  netapp_commands :securityloginlock    => 'security-login-lock'
  netapp_commands :securityloginunlock  => 'security-login-unlock'

  mk_resource_methods

  def self.instances
    securitylogins = []
    results = securityloginlist() || []
    results.each do |securitylogin|
      application = securitylogin.child_get_string('application')
      authentication_method = securitylogin.child_get_string('authentication-method')
      username = securitylogin.child_get_string('user-name')
      vserver = securitylogin.child_get_string('vserver')
      securitylogin_hash = {
        :name              => "#{application}:#{authentication_method}:#{username}:#{vserver}",
        :password          => securitylogin.child_get_string('password'),
        :comment           => securitylogin.child_get_string('comment'),
        :role_name         => securitylogin.child_get_string('role-name'),
        :snmpv3_login_info => securitylogin.child_get_string('snmpv3-login-info'),
        :is_locked         => securitylogin.child_get_string('is-locked'),
        :ensure            => :present,
      }
      securitylogins << new(securitylogin_hash)
    end
    securitylogins
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    application, authentication_method, username, vserver = resource[:name].split(':')
    args = Array.new
    args += ['user-name', username]
    args += ['vserver', vserver]

    case @property_hash[:ensure]
    when :absent
      args += ['authentication-method', authentication_method]
      args += ['application', application]

      securitylogindestroy(*args)
    when :present
      #if lock status changes, do the right thing
      if @original_values[:is_locked] != is_locked
        if is_locked
          securityloginlock(*args)
        else
          securityloginunlock(*args)
        end
      end

      securityloginmodify(*get_args)
    end
  end

  def create
    securitylogincreate(*get_args)
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
    application, authentication_method, username, vserver = resource[:name].split(':')
    args += ['user-name', username]
    args += ['authentication-method', authentication_method]
    args += ['role-name', resource[:role_name]]
    args += ['snmpv3-login-info', resource[:snmpv3_login_info]] unless resource[:snmpv3_login_info].nil?
    args += ['application', application]
    args += ['vserver', vserver]
    args += ['comment', resource[:comment]]
    args
  end
end
