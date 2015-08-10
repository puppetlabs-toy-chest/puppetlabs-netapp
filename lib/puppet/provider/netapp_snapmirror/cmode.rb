require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_snapmirror).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp snapmirror"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :snapmirrorlist     => {:api => 'snapmirror-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :snapmirrorcreate   => 'snapmirror-create'
  netapp_commands :snapmirrordestroy  => 'snapmirror-destroy'
  netapp_commands :snapmirrormodify   => 'snapmirror-modify'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    snapmirrors = []
    results = snapmirrorlist() || []
    results.each do |snapmirror|
      snapmirror_hash = {
        :name              => snapmirror.child_get_string('destination-location'),
        :source_location   => snapmirror.child_get_string('source-location'),
        :max_transfer_rate => snapmirror.child_get_string('max-transfer-rate'),
        :relationship_type => snapmirror.child_get_string('relationship-type'),
        :ensure            => :present,
      }
      snapmirrors << new(snapmirror_hash)
    end
    snapmirrors
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
      snapmirrordestroy('destination-location',resource[:name])
    when :present
      snapmirrormodify(*get_args('modify'))
    end
  end

  def create
    snapmirrorcreate(*get_args('create'))
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args (method)
    args = NaElement.new("snapmirror-#{method}")
    args.child_add_string('destination-location', @resource[:name])
    args.child_add_string('source-location', @resource[:source_location])
    args.child_add_string('relationship-type', @resource[:relationship_type])
    args.child_add_string('max-transfer-rate', @resource[:max_transfer_rate])

    args
  end
end
