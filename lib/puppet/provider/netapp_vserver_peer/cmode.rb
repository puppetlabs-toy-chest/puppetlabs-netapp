require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_vserver_peer).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Vapplication Peering"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :vserverpeerlist     => {:api => 'vserver-peer-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :vserverpeercreate   => 'vserver-peer-create'
  netapp_commands :vserverpeerdestroy  => 'vserver-peer-delete'
  netapp_commands :vserverpeermodify   => 'vserver-peer-modify'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    vserverpeers = []
    results = vserverpeerlist() || []
    results.each do |vserverpeer|
      # Servers
      applications = []
      unless vserverpeer.child_get("applications").nil?
        applications_info = vserverpeer.child_get("applications").children_get()
        applications_info.each do |application|
          applications << application.content()
        end unless applications_info.nil?
      end
      vserverpeer_hash = {
        :name         => "#{vserverpeer.child_get_string('vserver')}:#{vserverpeer.child_get_string('peer-vserver')}",
        :peer_cluster => vserverpeer.child_get_string('peer-cluster'),
        :applications => applications,
        :ensure       => :present,
      }
      vserverpeers << new(vserverpeer_hash)
    end
    vserverpeers
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
      vserver, peer_vserver = @resource[:name].split(':')
      vserverpeerdestroy('vserver', vserver, 'peer-vserver', peer_vserver)
    when :present
      vserverpeermodify(*get_args('modify'))
    end
  end

  def create
    vserverpeercreate(*get_args('create'))
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args (method)
    args = NaElement.new("vserver-peer-#{method}")
    vserver, peer_vserver = @resource[:name].split(':')
    args.child_add_string('vserver', vserver)
    args.child_add_string('peer-vserver', peer_vserver)
    if method == 'create'
      args.child_add_string('peer-cluster', @resource[:peer_cluster])
    end

    unless @resource[:applications].nil?
      element = NaElement.new('applications')
      Array(@resource[:applications]).each do |application|
        element.child_add_string('vserver-peer-application', application)
      end
      args.child_add(element)
    end
#require 'pry'; binding.pry
    args
  end
end
