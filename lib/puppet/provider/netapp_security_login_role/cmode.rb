require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_security_login_role).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp security login roles. [Family: cluster]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :securityloginrolelist    => {:api => 'security-login-role-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :securityloginrolecreate  => 'security-login-role-create'
  netapp_commands :securityloginroledestroy => 'security-login-role-delete'
  netapp_commands :securityloginrolemodify  => 'security-login-role-modify'

  mk_resource_methods

  def self.instances
    securityloginroles = []
    results = securityloginrolelist() || []
    results.each do |securityloginrole|
      command_directory_name  = securityloginrole.child_get_string('command-directory-name')
      rolename = securityloginrole.child_get_string('role-name')
      vserver = securityloginrole.child_get_string('vserver')
      securityloginrole_hash = {
        :name         => "#{command_directory_name}:#{rolename}:#{vserver}",
        :access_level => securityloginrole.child_get_string('access-level'),
        :role_query   => securityloginrole.child_get_string('role-query'),
        :ensure       => :present,
      }
      securityloginroles << new(securityloginrole_hash)
    end
    securityloginroles
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
      command_directory_name, rolename, vserver = resource[:name].split(':')
      args = Array.new
      args += ['command-directory-name', command_directory_name]
      args += ['role-name', rolename]
      args += ['vserver', vserver]

      securityloginroledestroy(*args)
    when :present
      securityloginrolemodify(*get_args)
    end
  end

  def create
    securityloginrolecreate(*get_args)
    @property_hash.clear
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args
    command_directory_name, rolename, vserver = resource[:name].split(':')
    args = Array.new
    args += ['command-directory-name', command_directory_name]
    args += ['role-name', rolename]
    args += ['vserver', vserver]
    args += ['access-level', resource[:access_level]]
    args += ['role-query', resource[:role_query]]
    args
  end
end
