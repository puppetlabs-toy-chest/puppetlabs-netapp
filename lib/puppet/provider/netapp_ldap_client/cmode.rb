require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_ldap_client).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp LDAP client. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :ldapclientlist     => {:api => 'ldap-client-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :ldapclientcreate   => 'ldap-client-create'
  netapp_commands :ldapclientdestroy  => 'ldap-client-delete'
  netapp_commands :ldapclientmodify   => 'ldap-client-modify'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    ldapclients = []
    results = ldapclientlist() || []
    results.each do |ldapclient|
      # Servers
      servers = []
      unless ldapclient.child_get("servers").nil?
        servers_info = ldapclient.child_get("servers").children_get()
        servers_info.each do |server|
          servers << server.content()
        end unless servers_info.nil?
      end
      # preferred_ad_servers
      preffered_servers = []
      unless ldapclient.child_get("preferred-ad-servers").nil?
        preffered_servers_info = ldapclient.child_get("preferred-ad-servers").children_get()
        preffered_servers_info.each do |server|
          preffered_servers << preffered_server.content()
        end unless preffered_servers_info.nil?
      end
      ldapclient_hash = {
        :name                       => ldapclient.child_get_string('ldap-client-config'),
        :ad_domain                  => ldapclient.child_get_string('ad-domain'),
        :allow_ssl                  => ldapclient.child_get_string('allow-ssl'),
        :base_dn                    => ldapclient.child_get_string('base-dn'),
        :base_scope                 => ldapclient.child_get_string('base-scope'),
        :bind_as_cifs_server        => ldapclient.child_get_string('bind-as-cifs-server'),
        :bind_dn                    => ldapclient.child_get_string('bind-dn'),
        :bind_password              => ldapclient.child_get_string('bind-password'),
        :group_dn                   => ldapclient.child_get_string('group-dn'),
        :group_scope                => ldapclient.child_get_string('group-scope'),
        :is_netgroup_byhost_enabled => ldapclient.child_get_string('is-netgroup-byhost-enabled'),
        :min_bind_level             => ldapclient.child_get_string('min-bind-level'),
        :netgroup_byhost_dn         => ldapclient.child_get_string('netgroup-byhost-dn'),
        :netgroup_byhost_scope      => ldapclient.child_get_string('netgroup-byhost-scope'),
        :netgroup_dn                => ldapclient.child_get_string('netgroup-dn'),
        :netgroup_scope             => ldapclient.child_get_string('netgroup-scope'),
        :preferred_ad_servers       => preffered_servers,
        :query_timeout              => ldapclient.child_get_string('query-timeout'),
        :schema                     => ldapclient.child_get_string('schema'),
        :servers                    => servers,
        :tcp_port                   => ldapclient.child_get_string('tcp-port'),
        :use_start_tls              => ldapclient.child_get_string('use-start-tls'),
        :user_dn                    => ldapclient.child_get_string('user-dn'),
        :user_scope                 => ldapclient.child_get_string('user-scope'),
        :ensure                     => :present,
      }
      ldapclients << new(ldapclient_hash)
    end
    ldapclients
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
      ldapclientdestroy('ldap-client-config',resource[:name])
    when :present
      ldapclientmodify(*get_args('modify'))
    end
  end

  def create
    ldapclientcreate(*get_args('create'))
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args (method)
    args = NaElement.new("ldap-client-#{method}")
    args.child_add_string('ldap-client-config', @resource[:name])
    args.child_add_string('ad-domain', @resource[:ad_domain])
    args.child_add_string('allow-ssl', @resource[:allow_ssl]) unless @resource[:allow_ssl].nil?
    args.child_add_string('base-dn', @resource[:base_dn]) unless @resource[:base_dn].nil?
    args.child_add_string('base-scope', @resource[:base_scope])
    args.child_add_string('bind-as-cifs-server', @resource[:bind_as_cifs_server])
    args.child_add_string('bind-dn', @resource[:bind_dn]) unless @resource[:bind_dn].nil?
    args.child_add_string('bind-password', @resource[:bind_password])
    args.child_add_string('group-dn', @resource[:group_dn]) unless @resource[:group_dn].nil?
    args.child_add_string('group-scope', @resource[:group_scope])
    args.child_add_string('is-netgroup-byhost-enabled', @resource[:is_netgroup_byhost_enabled]) unless @resource[:is_netgroup_byhost_enabled].nil?
    args.child_add_string('min-bind-level', @resource[:min_bind_level])
    args.child_add_string('netgroup-byhost-dn', @resource[:netgroup_byhost_dn]) unless @resource[:netgroup_byhost_dn].nil?
    args.child_add_string('netgroup-byhost-scope', @resource[:netgroup_byhost_scope])
    args.child_add_string('netgroup-dn', @resource[:netgroup_dn]) unless @resource[:netgroup_dn].nil?
    args.child_add_string('netgroup-scope', @resource[:netgroup_scope])
    args.child_add_string('query-timeout', @resource[:query_timeout]) unless @resource[:query_timeout].nil?
    args.child_add_string('schema', @resource[:schema])
    args.child_add_string('tcp-port', @resource[:tcp_port]) unless @resource[:tcp_port].nil?
    args.child_add_string('use-start-tls', @resource[:use_start_tls]) unless @resource[:use_start_tls].nil?
    args.child_add_string('user-dn', @resource[:user_dn]) unless @resource[:user_dn].nil?
    args.child_add_string('user-scope', @resource[:user_scope])

    # Add servers array
    unless @resource[:servers].nil?
      addresses_element = NaElement.new('servers')
      Array(@resource[:servers]).each do |server|
        addresses_element.child_add_string('ip-address', server)
      end
      args.child_add(addresses_element)
    end
    # Add preffered_servers array
    unless @resource[:preffered_ad_servers].nil?
      preffered_addresses_element = NaElement.new('preffered-ad-servers')
      Array(@resource[:preffered_ad_servers]).each do |server|
        preffered_addresses_element.child_add_string('ip-address', server)
      end
      args.child_add(preffered_addresses_element)
    end

    args
  end
end
