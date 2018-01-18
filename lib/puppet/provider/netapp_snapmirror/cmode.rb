require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_snapmirror).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp snapmirror. [Family: cluster, vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :snapmirrorlist       => {:api => 'snapmirror-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :snapmirrorcreate     => 'snapmirror-create'
  netapp_commands :snapmirrorinitialize => 'snapmirror-initialize'
  netapp_commands :snapmirrordestroy    => 'snapmirror-destroy'
  netapp_commands :snapmirrormodify     => 'snapmirror-modify'

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
        :name                => snapmirror.child_get_string('destination-location'),
        :source_location     => snapmirror.child_get_string('source-location'),
        :max_transfer_rate   => snapmirror.child_get_string('max-transfer-rate'),
        :relationship_type   => snapmirror.child_get_string('relationship-type'),
        :snapmirror_policy   => snapmirror.child_get_string('policy'),
        :snapmirror_schedule => snapmirror.child_get_string('schedule'),
        :ensure              => :present,
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
    snapmirrorinitialize(*get_args('initialize'))
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def get_args (method)
    # Parameters supported by snapmirror-create,snapmirror-modify and snapmirror-initialize APIs
    args = NaElement.new("snapmirror-#{method}")
    args.child_add_string('destination-location', @resource[:name])
    args.child_add_string('source-location', @resource[:source_location]) unless @resource[:source_location].nil?
    args.child_add_string('max-transfer-rate', @resource[:max_transfer_rate]) unless @resource[:max_transfer_rate].nil?
    if method != 'initialize'
        # Parameters not supported by snapmirror-initialize API
        args.child_add_string('policy', @resource[:snapmirror_policy]) unless @resource[:snapmirror_policy].nil?
        args.child_add_string('schedule', @resource[:snapmirror_schedule]) unless @resource[:snapmirror_schedule].nil?
        if method != 'modify'
                # Parameter not supported by snapmirror-modify and snapmirror-initialize APIs
                args.child_add_string('relationship-type', @resource[:relationship_type]) unless @resource[:relationship_type].nil?
        end
    end
    args
  end
end
