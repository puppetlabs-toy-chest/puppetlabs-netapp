Puppet::Type.newtype(:netapp_system_node_autosupport) do
  @doc = 'Manage Netapp system node autosupport configuration. [Family: cluster]'

  apply_to_device

  newparam(:name) do
    desc 'The node name.'
    isnamevar
    validate do |value|
      raise ArgumentError, '#{value} is a invalid node name' unless value =~ /^[a-zA-Z0-9\-_.]+$/
    end
  end

  newproperty(:periodic_tx_window) do
    desc 'The transmission window in format [<integer>h][<integer>m][<integer>s]'
  end
end
