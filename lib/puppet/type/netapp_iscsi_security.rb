Puppet::Type.newtype(:netapp_iscsi_security) do
  @doc = "Manage Netap ISCSI initiator (client) authentication"

  apply_to_device

  ensurable

  newparam(:initiator) do
    desc "ISCSI initiator name"
    isnamevar
  end

  newproperty(:auth_type) do
    desc "ISCSI initiator authentication type."
    newvalues(:chap, :none, :deny)
  end

  newproperty(:radius) do
    desc "ISCSI radius CHAP"
    newvalues(:true,:false)
  end

  newproperty(:username) do
    desc "ISCSI CHAP username"
  end

  newparam(:password) do
    desc "ISCSI CHAP password. Valid values are 12-16 hexidecimal digits."
    validate do |value|
      if ! value.to_s.match(%r{^\h{12,16}$})
        err "Password must be 12-16 hexidecimal digits"
      end
    end
    munge do |value|
      value.to_s
    end
  end

  newproperty(:outbound_username) do
    desc "ISCSI CHAP outbound username"
  end

  newparam(:outbound_password) do
    desc "ISCSI CHAP outbound password. Valid values are 12-16 hexidecimal digits."
    validate do |value|
      if ! value.to_s.match(%r{^\h{12,16}$})
        err "Outbound password must be 12-16 hexidecimal digits"
      end
    end
    munge do |value|
      value.to_s
    end
  end
end
