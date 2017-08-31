require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_net_dns).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp DNS server mapping. [Family: vserver]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :netdnsoptlist => {:api => 'net-dns-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :netdnsmdfy    => 'net-dns-modify'
  netapp_commands :netdnscreate  => 'net-dns-create'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_net_dns.cmode self.instances: Got to self.instances.")

    vserver_services_name_service_dns_infos = []
    results = netdnsoptlist() || []
    domains = []
    name_servers = []

    results.each do |result|
      unless result.child_get("domains").nil?
        domains_info = result.child_get("domains").children_get()
        domains_info.each do |string|
          domains << string.content()
        end unless domains_info.nil?
      end

      unless result.child_get("name-servers").nil?
        name_servers_info = result.child_get("name-servers").children_get()
        name_servers_info.each do |ip_address|
          name_servers << ip_address.content()
        end unless name_servers_info.nil?
      end

      vserver_services_name_service_dns_hash = {
        :name         => result.child_get_string('vserver-name'),
        :domains      => domains, 
        :state        => result.child_get_string('dns-state'),
        :name_servers => name_servers,
        :ensure       => :present,
      }
    vserver_services_name_service_dns_infos << new(vserver_services_name_service_dns_hash)
    end
    vserver_services_name_service_dns_infos
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_net_dns.cmode: Got to self.prefetch.")
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_net_dns.cmode flush: Got to flush for resource.")
    netdnsmdfy(*get_args('modify'))
  end

  def get_args (method)
    args = NaElement.new("net-dns-#{method}")
    args.child_add_string('dns-state', @resource[:state]) unless @resource[:state].nil?

    unless @resource[:domains].nil?
       domain_element = NaElement.new('domains')
       Array(@resource[:domains]).each do |domain|
         domain_element.child_add_string('string', domain)
       end
       args.child_add(domain_element)
    end

    unless @resource[:name_servers].nil?
      addresses_element = NaElement.new('name-servers')
      Array(@resource[:name_servers]).each do |server|
        addresses_element.child_add_string('ip-address', server)
      end
      args.child_add(addresses_element)
    end
    args
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_net_dns.comde: creating resource.")
    result = netdnscreate(*get_args('create'))
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_net_dns.cmode: cannot destroy resource.") 
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_net_dns.cmode: checking existance.")
    @property_hash[:ensure] == :present
  end
end
