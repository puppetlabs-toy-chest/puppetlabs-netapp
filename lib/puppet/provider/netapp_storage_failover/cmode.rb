require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_storage_failover).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage storage failover. [Family: cluster]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands   :strgfailovershow  => {:api => 'cf-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands   :strgfailovermdfy  => 'cf-modify-iter'
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_storage_failover.cmode: Got to self.instances")
    strgfailoverinfos = []
    results = strgfailovershow() || []

    results.each do |storage_failover_info|
      unless storage_failover_info.nil?
        sfo_options_info  = storage_failover_info.child_get('sfo-options-info')
        unless sfo_options_info.nil?
          options_related_info = sfo_options_info.child_get('options-related-info')
          unless options_related_info.nil?
            sfo_giveback_options_info = options_related_info.child_get('sfo-giveback-options-info')
            unless sfo_giveback_options_info.nil?
              giveback_options = sfo_giveback_options_info.child_get('giveback-options')
              unless giveback_options.nil?
                auto_giveback_after_panic_enabled = giveback_options.child_get_string('auto-giveback-after-panic-enabled')
                auto_giveback_enabled = giveback_options.child_get_string('auto-giveback-enabled')
                auto_giveback_override_vetoes_enabled = giveback_options.child_get_string('auto-giveback-override-vetoes-enabled')
              end
            end
          end
        end
        sfo_node_info = storage_failover_info.child_get('sfo-node-info')
        unless sfo_node_info.nil?
          node_related_info = sfo_node_info.child_get('node-related-info')
          unless node_related_info.nil?
            node = node_related_info.child_get_string('node')
          end
        end
      end
      strg_failover_info_hash = {
        :name       => node,
        :auto_giveback => auto_giveback_enabled,
        :auto_giveback_after_panic => auto_giveback_after_panic_enabled,
        :auto_giveback_override_vetoes => auto_giveback_override_vetoes_enabled,
        :ensure => :present
      }
      strgfailoverinfos << new(strg_failover_info_hash)
    end
    strgfailoverinfos
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_storage_failover.cmode: Got to prefetch")
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
      strgfailovermdfy(*get_args('modify'))
  end

  def get_args (method)
    args = NaElement.new("cf-#{method}-iter")

    attributes = NaElement.new("attributes")
    options_related_info_modify = NaElement.new("options-related-info-modify")
    attributes.child_add(options_related_info_modify)
    sfo_giveback_options_info_modify = NaElement.new("sfo-giveback-options-info-modify")
    options_related_info_modify.child_add(sfo_giveback_options_info_modify)
    options_related_info_modify.child_add_string('node', @resource[:name])
    giveback_options_modify = NaElement.new("giveback-options-modify")
    sfo_giveback_options_info_modify.child_add(giveback_options_modify)
    giveback_options_modify.child_add_string('auto-giveback-after-panic-enabled', @resource[:auto_giveback_after_panic]) unless @resource[:auto_giveback_after_panic].nil?
    giveback_options_modify.child_add_string('auto-giveback-enabled', @resource[:auto_giveback]) unless @resource[:auto_giveback].nil?
    giveback_options_modify.child_add_string('auto-giveback-override-vetoes-enabled', @resource[:auto_giveback_override_vetoes]) unless @resource[:auto_giveback_override_vetoes].nil?
    args.child_add(attributes)

    query = NaElement.new("query")
    options_related_info_modify_query = NaElement.new("options-related-info-modify")
    options_related_info_modify_query.child_add_string('node', @resource[:name]) 
    query.child_add(options_related_info_modify_query)
    args.child_add(query)

    args
  end
end
