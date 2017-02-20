require 'puppet/provider/netapp_cmode'

Puppet::Type.type(:netapp_options).provide(:cmode, :parent => Puppet::Provider::NetappCmode) do
  @doc = "Manage Netapp system options"

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :optionlist => {:api => 'options-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :optionset  => 'options-set'

  mk_resource_methods

  def self.instances
    options = []
    results = optionlist() || []
    results.each do |option|
require 'pry'; binding.pry
      option_hash = {
        :name   => option.child_get_string('name'),
        :value  => option.child_get_string('value'),
        :ensure => :present,
      }
      options << new(option_hash)
    end
    options
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
    when :present
      optionset(*get_args)
    end
  end

  def create
      optionset(*get_args)
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
    args += ['name', resource[:name]]
    args += ['value', resource[:value]]
    args
  end
end
