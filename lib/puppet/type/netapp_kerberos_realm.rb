require 'puppet/parameter/boolean'

Puppet::Type.newtype(:netapp_kerberos_realm) do
  @doc = "Kerberos realm configuration specifies the locations of Key Distribution Center (KDC) servers and administration daemons for the Kerberos realms of interest. When returned as part of the output, all elements of this typedef are reported, unless limited by a set of desired attributes specified by the caller. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:name) do
    desc "Kerberos realm name."
    isnamevar
  end

  newproperty(:ad_server_ip) do
    desc "IP Address of the Active Directory Domain Controller (DC). This is a mandatory parameter if the kdc-vendor is 'microsoft'."
  end

  newproperty(:ad_server_name) do
    desc "Host name of the Active Directory Domain Controller (DC). This is a mandatory parameter if the kdc-vendor is 'microsoft'"
  end

  newproperty(:admin_server_ip) do
    desc "IP address of the host where the Kerberos administration daemon is running. This is usually the master KDC. If this parameter is omitted, the IP address specified in kdc-ip is used. If specified, this should be the same as the kdc-ip if the kdc-vendor is 'microsoft'."
  end

  newproperty(:admin_server_port) do
    desc "The TCP port on the Kerberos administration server where the Kerberos administration service is running. The default for this parmater is 749."

    defaultto(749)
  end

  newproperty(:clock_skew) do
    desc "The clock skew in minutes is the tolerance for accepting tickets with time stamps that do not exactly match the host's system clock. The default for this parameter is 5 minutes."

    defaultto(5)
  end

  newproperty(:comment) do
    desc "Comment"
  end

  newproperty(:config_name) do
    desc "Kerberos configuration name."
  end

  newproperty(:kdc_ip) do
    desc "The vendor of the Key Distribution Centre (KDC) server. If the configuration uses a Microsoft Active Directory (AD) domain for authentication, this field should be 'microsoft'."
  end
  
  newproperty(:kdc_port) do
    desc "TCP port on the KDC to be used for Kerberos communication. The default for this parameter is 88."

    defaultto(88)
  end

  newproperty(:kdc_vendor) do
    desc "The vendor of the Key Distribution Centre (KDC) server. If the configuration uses a Microsoft Active Directory (AD) domain for authentication, this field should be 'microsoft'."
  end

  newproperty(:password_server_ip) do
    desc "IP address of the host where the Kerberos password-changing server is running. Typically, this is the same as the host indicated in the adminserver-ip. If this parameter is omitted, the IP address in kdc-ip is used."
  end

  newproperty(:password_server_port) do
    desc "The TCP port on the Kerberos password-changing server where the Kerberos password-changing service is running. The default for this parameter is 464."

    defaultto(464)
  end
end
