require_relative '../netapp_cmode'

Puppet::Type.type(:netapp_license).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp license management. Only supported by ONTAP 8.2 and newer. [Family: cluster]"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :licenseget    => 'license-v2-list-info'
  netapp_commands :licenseadd    => 'license-v2-add'
  netapp_commands :licensedelete => 'license-v2-delete'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_license self.instances: Got to self.instances.")

    licenses = []
    results = licenseget()

    licenses_info = results.child_get("licenses").children_get()
    licenses_info.each do |license_info|
      # Construct the license hash
      license_hash = {
        :name   => license_info.child_get('package').content,
        :ensure => :present,
      }

      Puppet.debug("Puppet::Provider::Netapp_license self.instances: license_info = #{license_hash}.")
      licenses << new(license_hash)
    end
    licenses
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_license: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_license: Got to flush for resource #{@resource[:name]}.")
    case @property_hash[:ensure]
    when :absent
      licensedelete(@resource[:package])
    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_license create: ....")
    args = NaElement.new("license-v2-add")
    element = NaElement.new('codes')
    element.child_add_string('license-code-v2', @resource[:codes])
    args.child_add(element)
    licenseadd(args)
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_license: Nothing to destroy...")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_license exists?: checking existance of Netapp license package #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end

end
