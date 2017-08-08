require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_cifs).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp CIFS server. [Family: vserver]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :cifslist    => {:api => 'cifs-server-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :cifscreate  => 'cifs-server-create'
  netapp_commands :cifsdelete  => 'cifs-server-delete'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_cifs.cmode self.instances: Got to self.instances.")

    cifs_infos = []
    results = cifslist() || []

    results.each do |result|
      cifs_info_hash = {
        :name    => result.child_get_string('cifs-server'),
        :domain  => result.child_get_string('domain'),
        :ensure  => :present
      }
    cifs_infos << new(cifs_info_hash)
    end
    cifs_infos
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_cifs.cMode: Got to self.prefetch.")
    instances.each do |prov|
      key = prov.name
      k = resources.keys.find{|k| k.downcase == key.downcase}
      if resource = (resources[k])
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_cifs.cMode flush: Got to flush for resource #{@resource[:name]}.")
    if @property_hash[:ensure] == :absent
      cifsdelete('admin-username', @resource[:admin_username], 'admin-password', @resource[:admin_password])
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_cifs.comde: creating resource.")
    result = cifscreate('cifs-server', @resource[:name], 'domain', @resource[:domain], 'admin-username', @resource[:admin_username], 'admin-password', @resource[:admin_password])
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_cifs.cmode:  destroy resource.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_cifs.cmode: checking existance.")
    @property_hash[:ensure] == :present
  end
end
