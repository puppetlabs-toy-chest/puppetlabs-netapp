require 'puppet/util/network_device/netapp'

class Puppet::Util::NetworkDevice::Netapp::Facts

  attr_reader :url, :transport
  def initialize(transport)
    @transport = transport
  end

  def retrieve(host)

    # Create empty hash
    @facts = {}

    # Invoke "system-get-version" to gather system version.
    result = @transport.invoke("system-get-version")

    return {} if result.attr_get("status") == "failed"
    # Pull out version
    sys_version = result.child_get_string("version")
    @facts['version'] = sys_version if sys_version

    if result.child_get_string("is-clustered") == "true"
      @facts['clustered'] = true
    else
      @facts['clustered'] = false
    end

    Puppet.debug("Clustered = #{@facts['clustered']}.")

    # cMode has differnt API's to 7Mode.
    if @facts['clustered'] and ! @facts.empty?
      # Get cluster Mode facts
      getClusterFacts(host)
    else
      # Get 7-Mode facts
      getSevenFacts
    end

    # cleanup of netapp output to match existing facter key values.
    map = {
      'system-name'          => 'hostname',
      'memory-size'          => 'memorysize_mb',
      'system-model'         => 'productname',
      'cpu-processor-type'   => 'hardwareisa',
      'vendor-id'            => 'manufacturer',
      'number-of-processors' => 'processorcount',
      'system-serial-number' => 'serialnumber',
      'system-id'            => 'uniqueid'
    }
    @facts = Hash[@facts.map {|k, v| [map[k] || k, v] }]\

    # Need to replace '-' with '_'
    @facts = Hash[@facts.map {|k, v| [k.to_s.gsub('-','_'), v] }]
    @facts['memorysize'] = "#{@facts['memorysize_mb']} MB"

    # Set operatingsystem details if present
    if @facts['version'] then
      if @facts['version'] =~ /^NetApp Release (\d.\d(.\d)?\w*)/i
        @facts['operatingsystem'] = 'OnTAP'
        @facts['operatingsystemrelease'] = $1
      end
    end

    # Downcase hostname for easier usage
    @facts['hostname'].downcase! if @facts['hostname']

    # Handle FQDN
    if @facts['domain']
      if @facts['hostname'].include?(@facts['domain'])
        # Hostname contains the domain, therefore must be FQDN
        @facts['fqdn'] = @facts['hostname']
        @facts['hostname'] = @facts['fqdn'].split('.',2).shift
      else
        # Hostname doesnt include domain.
        @facts['fqdn'] = "#{@facts['hostname']}.#{@facts['domain']}"
      end
    end

    Puppet.debug("Facts = #{@facts.inspect}")
    @facts

  end

  # Helper method to get clusterMode facts
  def getClusterFacts(host)

    #debugger
    Puppet.debug("Hostname = #{host}")

    # Check if connected to a vserver
    vserver = @transport.get_vserver()
    Puppet.debug("Current vserver = #{vserver}")

    if vserver.empty?
      Puppet.debug("Not connected to a vserver, so gather system facts")

      # Pull out node system-info
      result = @transport.invoke("system-get-node-info-iter")
      Puppet.debug("Result = #{result.inspect}")

      # Pull out attributes-list and itterate
      systems = result.child_get("attributes-list")
      system_host = systems.children_get().find do |system|
        # Check the system name matches the host we're looking for
        Puppet.debug("System-name = #{system.child_get_string('system-name')}. downcase = #{system.child_get_string("system-name").downcase}")
        Puppet.debug("Match = #{host.downcase == system.child_get_string("system-name").downcase}")
        host.downcase == system.child_get_string("system-name").downcase
      end

      if system_host
        # Pull out the required variables
        [
          'system-name',
          'system-id',
          'system-model',
          'system-machine-type',
          'system-serial-number',
          'partner-system-id',
          'partner-serial-number',
          'system-revision',
          'number-of-processors',
          'memory-size',
          'cpu-processor-type',
          'vendor-id',
        ].each do |key|
          @facts[key] = system_host.child_get_string("#{key}".to_s)
        end

        # Facts dump
        Puppet.debug("System info = #{@facts.inspect}")
      else
        raise ArgumentError, "No matching system found with the system name #{host}"
      end

      # Get DNS domainname for fqdn
      #result = @transport.invoke("options-get-iter")
    end

    @facts

  end

  # Helper method to get 7-Mode facts
  def getSevenFacts()

    # Invoke "system-get-info" call to gather system information.
    result = @transport.invoke("system-get-info")

    # Pull out system-info subset.
    sys_info = result.child_get("system-info")

    # Array of values to get
    [
      'system-name',
      'system-id',
      'system-model',
      'system-machine-type',
      'system-serial-number',
      'partner-system-id',
      'partner-serial-number',
      'system-revision',
      'number-of-processors',
      'memory-size',
      'cpu-processor-type',
      'vendor-id',
    ].each do |key|
      @facts[key] = sys_info.child_get_string("#{key}".to_s)
    end

    # Get DNS domainname to build up fqdn
    result = @transport.invoke("options-get", "name", "dns.domainname")
    domain_name = result.child_get_string("value")
    @facts['domain'] = domain_name.downcase if domain_name

    # Get the network config
    result = @transport.invoke("net-ifconfig-get")
    if result.results_status == 'failed'
      Puppet.debug "API call net-ifconfig-get failed. Probably not supported. Not gathering interface facts"
    else
      # Create an empty array to hold interface list
      interfaces = []
      # Create an empty hash to hold interface_config
      interface_config = {}

      # Get an array of interfaces
      ifconfig = result.child_get("interface-config-info")
      ifconfig = ifconfig.children_get()
      # Itterate over interfaces
      ifconfig.each do |iface|
        iface_name = iface.child_get_string("interface-name")
        iface_mac = iface.child_get_string("mac-address")
        iface_mtu = iface.child_get_string("mtusize")

        # Need to dig deeper to get IP address'
        iface_ips = iface.child_get("v4-primary-address")
        if iface_ips
          iface_ips = iface_ips.child_get("ip-address-info")
          iface_ip = iface_ips.child_get_string("address")
          iface_netmask = iface_ips.child_get_string("netmask-or-prefix")
        end

        # Populate interfaces array
        interfaces << iface_name
        # Populate interface_config
        interface_config["ipaddress_#{iface_name}"] = iface_ip if iface_ip
        interface_config["macaddress_#{iface_name}"] = iface_mac if iface_mac
        interface_config["mtu_#{iface_name}"] = iface_mtu if iface_mtu
        interface_config["netmask_#{iface_name}"] = iface_netmask if iface_netmask
      end

      # Add network details to @facts hash
      @facts['interfaces'] = interfaces.join(",")
      @facts.merge!(interface_config)
      # Copy e0M config into top-level network facts
      @facts['ipaddress']  = @facts['ipaddress_e0M'] if @facts['ipaddress_e0M']
      @facts['macaddress'] = @facts['macaddress_e0M'] if @facts['macaddress_e0M']
      @facts['netmask']    = @facts['netmask_e0M'] if @facts['netmask_e0M']
    end
  end

end
