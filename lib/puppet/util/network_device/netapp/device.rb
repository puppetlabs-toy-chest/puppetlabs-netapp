require 'puppet/util/network_device'
require 'puppet/util/network_device/netapp/facts'
require 'puppet/util/network_device/netapp/NaServer'
require 'uri'

#require 'addressable/uri'

class Puppet::Util::NetworkDevice::Netapp::Device

  attr_accessor :url, :transport
  def initialize(url, option = {})
    @url = URI.parse(url)
    redacted_url = @url.dup
    redacted_url.password = "****" if redacted_url.password

    Puppet.debug("Puppet::Device::Netapp: connecting to Netapp device #{redacted_url}")

    raise ArgumentError, "Invalid scheme #{@url.scheme}. Must be https" unless @url.scheme == 'https'
    raise ArgumentError, "no user specified" unless @url.user
    raise ArgumentError, "no password specified" unless @url.password

    @transport ||= NaServer.new(@url.host, 1, 15)
    @transport.set_admin_user(@url.user, @url.password)
    @transport.set_transport_type(@url.scheme.upcase)
    @transport.set_port(@url.port)

    # Get Vserver/Vfiler component
    if match = %r{/([^/]+)}.match(@url.path)
      @v = match.captures[0]
    end

    result = @transport.invoke("system-get-version")
    if(result.results_errno != 0)
      r = result.results_reason
      raise Puppet::Error, "invoke system-get-version failed: #{r}"
    else
      version = result.child_get_string("version")
      Puppet.debug("Puppet::Device::Netapp: Version = #{version}")
    end

    if @v
      # Vserver or vfiler based on if clustered?
      clustered = result.child_get_string("is-clustered")
      Puppet.debug("Clustered = #{clustered}.")

      if clustered
        Puppet.debug("Puppet::Device::Netapp: Setting vserver context to #{@v}")
        @transport.set_vserver(@v)
      else
        Puppet.debug("Puppet::Device::Netapp: Setting vfiler context to #{@v}")
        @transport.set_vfiler(@v)
      end
    end

  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Netapp::Facts.new(@transport)
    facts = @facts.retrieve(@url.host)

    facts
  end
end
