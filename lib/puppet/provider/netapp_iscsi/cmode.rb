require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_iscsi).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp iscsi service"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :iscsilist    => {:api => 'iscsi-service-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :iscsicreate  => 'iscsi-service-create'
  netapp_commands :iscsidestroy => 'iscsi-service-destroy'
  netapp_commands :iscsimodify  => 'iscsi-service-modify'
  netapp_commands :iscsistart   => 'iscsi-service-start'
  netapp_commands :iscsistop    => 'iscsi-service-stop'

  mk_resource_methods

  def self.instances
    iscsis = []
    results = iscsilist() || []
    results.each do |iscsi|
      vserver = iscsi.child_get_string('vserver')
      target_alias = iscsi.child_get_string('alias-name')
      iscsi_hash = {
        :name         => vserver,
        :ensure       => :present,
        :target_alias => target_alias,
      }

      iscsi_state = iscsi.child_get_string('is-available')
      if iscsi_state == 'true'
        iscsi_hash[:state] = 'on'
      else
        iscsi_hash[:state] = 'off'
      end

      iscsis << new(iscsi_hash)
    end
    iscsis
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_hash[:ensure] == :absent
      iscsistop()
      iscsidestroy()
    elsif ! @property_hash.empty?
      [:target_alias].each do |property|
        if @property_hash[property] and @property_hash[property] != @original_values[property]
          err "Cannot change #{property} after creation"
        end
      end
      iscsimodify(*get_args)
    end
  end

  def state=(value)
    case resource[:state]
    when :on
      iscsistart()
    when :off
      iscsistop()
    end
  end

  def create
    iscsicreate(*get_args)
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
    # Alias-name is write-only
    #args += ['alias-name', resource[:target_alias]] if resource[:target_alias]
    args
  end
end
