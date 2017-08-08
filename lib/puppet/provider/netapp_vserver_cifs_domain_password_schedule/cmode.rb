require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_vserver_cifs_domain_password_schedule).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp vserver cifs domain password schedule. [Family: vserver]"

  confine    :feature => :posix
  defaultfor :feature => :posix

  netapp_commands   :cifs_domain_password_schedulelist  => {:api => 'cifs-domain-password-schedule-get-iter ', :iter => true, :result_element => 'attributes-list'}
  netapp_commands   :cifs_domain_password_schedulemodify  => 'cifs-domain-password-schedule-modify'
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_vserver_cifs_domain_password_schedule.cmode self.instances: Got to self.instances.")
    cifs_domain_password_schedules = []
    results = cifs_domain_password_schedulelist() || []

    results.each do |result|
      cifs_domain_password_schedule_info = {
        :name                       => result.child_get_string('vserver'),
        :schedule_randomized_minute => result.child_get_string('schedule-randomized-minute'),
        :ensure                     => :present
      } 
      cifs_domain_password_schedules << new(cifs_domain_password_schedule_info)
    end
    cifs_domain_password_schedules
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_vserver_cifs_domain_password_schedule.cMode: Got to self.prefetch.")
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_vserver_cifs_domain_password_schedule.cMode flush: Got to flush for resource #{@resource[:name]}.")
    result = cifs_domain_password_schedulemodify('schedule-randomized-minute', @resource[:schedule_randomized_minute])
  end
end
