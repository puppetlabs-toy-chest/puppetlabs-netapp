require_relative '../../puppet_x/puppetlabs/netapp/property/netapp_truthy'

Puppet::Type.newtype(:netapp_sis_policy) do
  @doc = "Manage Netapp sis policy modification. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The efficiency policy name"
    isnamevar
  end

  newproperty(:type) do
    desc "Policy type."
    newvalues(:threshold, :scheduled)
  end

  newproperty(:job_schedule) do
    desc "Job schedule name. Eg: 'daily'"
  end

  newproperty(:duration) do
    desc "Job duration in hours."
  end

  newproperty(:enabled, :parent => Puppet::Property::NetappTruthy) do
    truthy_property("Manage whether the sis policy is enabled.")
  end

  newproperty(:comment) do
    desc "Comment for the policy"
  end

  newproperty(:changelog_threshold_percent) do
    desc "Percentage at which the changelog will be processed for a threshold type of policy, tested once each hour"
  end

  newproperty(:qos_policy) do
    desc "QoS Policy Name. Eg: 'best_effort'"
  end
end
