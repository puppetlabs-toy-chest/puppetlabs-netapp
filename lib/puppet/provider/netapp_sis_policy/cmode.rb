require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_sis_policy).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp Vserver sis config. [Family: vserver]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :sispollist   => {:api => 'sis-policy-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :sispolcreate => 'sis-policy-create'
  netapp_commands :sispoldelete => 'sis-policy-delete'
  netapp_commands :sispolmodify => 'sis-policy-modify'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_sis_policy.cmode: got to self.instances for cMode provider.")

    # Get vserver info
    results = sispollist() || []
    Puppet.debug("Puppet::Provider::Netapp_sis_policy.cmode instances: processing configs")

    sis_policies = []
    api_map = {
      'policy-name' => :name,
      'policy-type' => :type,
      'schedule'    => :job_schedule,
      'duration'    => :duration,
      'enabled'     => :enabled,
      'comment'     => :comment,
      'qos-policy'  => :qos_policy,
    }
    results.each do |sis_policy|
      policy_info = { :ensure => :present }
      sis_policy.children_get.each do |policy|
        case policy.content
        when 'true', 'enabled'
          value = true
        when 'false', 'disabled'
          value = false
        else
          value = policy.content
        end
        policy_info[api_map[policy.name]] = value if api_map[policy.name] and value != '-'
      end

      Puppet.debug("Puppet::Provider::Netapp_sis_policy.cmode instances: policy_info looks like: #{policy_info.inspect}")
      sis_policies << new(policy_info) if policy_info[:name]
    end
    sis_policies
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
      sispoldelete('policy-name', @property_hash[:name])
    when :present
      sispolmodify(*policy_arguments)
    end
  end

  def create
    sispolcreate(*policy_arguments)
  end
  def destroy
    @property_hash[:ensure] = :absent
  end
  def exists?
    @property_hash[:ensure] == :present
  end

  def policy_arguments
    args = Array.new
    args += ['policy-name', @resource[:name]]
    args += ['policy-type', @resource[:type]] if @resource[:type]
    args += ['schedule',    @resource[:job_schedule]] if @resource[:job_schedule]
    args += ['duration',    @resource[:duration]] if @resource[:duration]
    args += ['enabled',     @resource[:enabled]] if @resource[:enabled]
    args += ['comment',     @resource[:comment]] if @resource[:comment]
    args += ['qos-policy',  @resource[:qos_policy]] if @resource[:qos_policy]
    Puppet.debug("Puppet::Provider::Netapp_sis_policy.cmode policy_arguments: #{args.inspect}")
    args
  end
end
