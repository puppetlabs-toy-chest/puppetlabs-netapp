require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_vserver_sis_config).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Vserver sis config."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :sislist      => {:api => 'sis-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :sisenable    => 'sis-enable'
  netapp_commands :sisdisable   => 'sis-disable'
  netapp_commands :sissetconfig => 'sis-set-config'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode: got to self.instances for cMode provider.")

    # Get vserver info
    results = sislist()
    Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode instances: processing configs")

    sis_configs = []

    api_map = {
      #'compression-type'              => :compression_type,
      'is-compression-enabled'        => :compression,
      'is-idd-enabled'                => :idd,
      'is-inline-compression-enabled' => :inline_compression,
      'path'                          => :name,
      'policy'                        => :policy,
      'schedule'                      => :sis_schedule,
      'state'                         => :enabled,
      'quick-check-fsize'             => :quick_check_fsize,
    }

    # Itterate through the option-info blocks
    results.each do |sis_config|
      config_info = { :ensure => :present }
      sis_config.children_get.each do |config|
        # Pull out option name and value

        #Puppet.debug("Config name #{config.name}, value #{config.content}.")

        case config.content
        when 'true', 'enabled'
          value = true
        when 'false', 'disabled'
          value = false
        else
          value = config.content
        end
        config_info[api_map[config.name]] = value if api_map[config.name] and value != '-'
      end

      Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode instances: config_info looks like: #{config_info.inspect}")

      # Add to array
      sis_configs << new(config_info) if config_info[:name]
    end

    Puppet.debug("Processed all sis configs. Returning array.")
    # Return options array
    sis_configs

  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  # These must be handled specially because only one can be passed at a time
  def policy=(value)
    @property_flush[:policy] = value
  end
  def sis_schedule=(value)
    @property_flush[:sis_schedule] = value
  end

  def flush
    if exists?
      args = Array.new
      #args += ['compression-type',          @property_hash[:compression_type]]
      args += ['enable-compression',        @property_hash[:compression]]
      args += ['enable-idd',                @property_hash[:idd]]
      args += ['enable-inline-compression', @property_hash[:inline_compression]]
      args += ['path',                      @property_hash[:name]]
      args += ['policy-name',               @property_flush[:policy]] if @property_flush[:policy]
      args += ['schedule',                  @property_flush[:sis_schedule]] if @property_flush[:sis_schedule]
      args += ['quick-check-fsize',         @property_hash[:quick_check_fsize]]
      Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode flush: Sending to sis_set_config: #{args.inspect}")
      result = sissetconfig(*args)

      return true
    end
  end

  # Volume create.
  def enabled=(value)
    if value == true
      result = sisenable("path", @resource[:name])
      @property_hash[:enabled] = true
    elsif value == false
      result = sisdisable("path", @resource[:name])
      @property_hash = {
        :name   => @resource[:name],
        :ensure => :absent,
      }
    else
      raise ArgumentError, "Got #{value.inspect} for enabled"
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode: Can't create sis configs, only manage existing ones.")

    return true
  end
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_vserver_sis_config.cmode: Can't destroy sis configs, only volumes")
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
