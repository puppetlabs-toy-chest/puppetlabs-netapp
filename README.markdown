# NetApp Data ONTAP device module

[![Coverage Status](https://coveralls.io/repos/fatmcgav/fatmcgav-netapp/badge.png?branch=develop)](https://coveralls.io/r/fatmcgav/fatmcgav-netapp?branch=develop)

####Table of Contents

1. [Overview](#overview)
1. [Module Description](#module-description)
1. [Setup](#setup)
    * [Requirements](#requirements)
    * [NetApp Manageability SDK](#netapp-manageability-sdk)
    * [Device Proxy System Setup](#device-proxy-system-setup)
1. [Usage](#usage)
  * [Beginning with netapp](#beginning-with-netapp)
  * [Classes and Defined Types](#classes-and-defined-types)
  * [Types and Providers](#types-and-providers)
1. [Limitations](#limitations)
  * [TODO](#todo)
1. [Development](#development)
  * [Testing](#testing)
  * [Contributors](#contributors)

## Overview

The NetApp Data ONTAP device module is designed to add support for managing
NetApp Data ONTAP configuration using Puppet and its Network Device
functionality.

The NetApp Data ONTAP device module has been written and tested against NetApp
Data ONTAP 8.2 Cluster-mode.
<!--
- It may also work on 7-mode.
- It should be compatible with other ONTAP versions than just 8.2, but not tested
-->

## Module Description

This module uses the NetApp Manageability SDK to manage various aspects of the
NetApp Data ONTAP software.

The following items are supported:

 * Creation, modification and deletion of volumes, including auto-increment,
   snapshot schedules and volume options.
 * Creation, modification and deletion of QTrees.
 * Creation, modification and deletion of NFS Exports, including NFS export
   security.
 * Creation, modification and deletion of users, groups and roles.
 * Creation, modification and deletion of Quotas.
 * Creation of snapmirror relationships.
 * Creation of snapmirror schedules.

## Setup

## Requirements

Because we can not directly install Puppet on the NetApp Data ONTAP operating
system, it must be managed through an intermediate proxy system running `puppet
device`. The requirements for the proxy system are:

 * Puppet 3.7 or greater
 * NetApp Manageability SDK Ruby libraries
 * Faraday gem

The proxy system must be able to connect to the Puppet master (default port of
8140) and to the NetApp Data ONTAP (default port of 443).

### NetApp Manageability SDK

Due to licensing, you must download the NetApp Manageability SDK separately.
The NetApp Ruby libraries are contained within the NetApp Manageability SDK,
which is available for download from [NetApp
NOW](http://support.netapp.com/NOW/cgi-bin/software?product=NetApp+Manageability+SDK&platform=All+Platforms).

Please note that you need a NetApp NOW account to download the
SDK.

Once you have downloaded and extracted the SDK, the Ruby SDK libraries must be
copied into the module:

`$ cp netapp-manageability-sdk-5.*/lib/ruby/NetApp/*.rb [module dir]/netapp/lib/puppet/netapp_sdk/`

### Device Proxy System Setup

To configure a Data ONTAP device, you must create a proxy system
able to run `puppet device` and have a device.conf file that refers to the
NetApp ONTAP system or vserver. Refer to the [device.conf man
page](https://docs.puppetlabs.com/puppet/latest/reference/config_file_device.html)
for information on the format of device.conf.

The netapp module can manage two different kinds of devices: Data ONTAP cluster
operating system and Data ONTAP cluster vservers. The device `type` of the
device.conf entry is always `netapp`.

For example, if you had a Data ONTAP operating system with the node management
interface addressable by the DNS name of ontap01.example.com and credentials
of admin & netapp123, the device.conf entry would be:

~~~
[ontap01.example.com]
type netapp
url https://admin:netapp123@ontap01.example.com
~~~

Note: The device certname must match the hostname of the node.

You can also specify a virtual server to operate on by providing the connection
information for a physical system which is configured with the vserver and
specify a path in the url that represents the name of your vserver. For
example, if the above Data ONTAP node ontap01 is configured with a vserver
called "vserver01," the device entry could be:

~~~
[vserver01.example.com]
type netapp
url https://admin:netapp123@ontap01.example.com/vserver01
~~~

Note: The device certname does not need to match the hostname of the node as
with a system device entry.

You can place the device entries in the default `${confdir}/device.conf` file
or create a separate config file for each device. For example, the above examples could
go in `${confdir}/device/ontap01.example.com.conf` and
`${confdir}/device/vserver01.example.com.conf`. Device configurations in separate files must be specified by `puppet device --deviceconfig /path/to/device-file.conf` to be used by `puppet device` run.

## Usage

### Beginning with netapp

Continuing from the example in [Device Proxy System
Setup](#device-proxy-system-setup), we can define a node definition for
ontap01.example.com to create a vserver with an aggregate of 6 disks and a LIF:

<!-- similar to https://library.netapp.com/ecmdocs/ECMP1196798/html/GUID-6D897853-FE9E-430C-971E-47096FDD462E.html -->

~~~
node 'ontap01.example.com' {
  netapp_aggregate { 'aggr1':
    ensure    => present,
    diskcount => '6',
  }
  netapp_vserver { 'vserver01':
    ensure          => present,
    rootvol         => 'vserver01_root',
    rootvolaggr     => 'aggr1',
    rootvolsecstyle => 'unix',
  }
  netapp_lif { 'vserver01_lif':
    ensure        => present,
    homeport      => 'e0c',
    homenode      => 'ontap01',
    address       => '10.0.207.5',
    vserver       => 'vserver01',
    netmask       => '255.255.255.0',
    dataprotocols => ['nfs'],
  }
}
~~~

Next we should create a node definition for the vserver with a volume that has export policies for NFS, and a qtree on the volume:

~~~
node 'vserver01.example.com' {
  netapp_export_policy { 'nfs_exports':
    ensure => present,
  }
  netapp_export_rule { 'nfs_exports:1':
    ensure            => present,
    clientmatch       => '10.0.0.0/8',
    protocol          => ['nfs'],
    superusersecurity => 'none',
    rorule            => ['sys','none'],
    rwrule            => ['sys','none'],
  }
  netapp_volume { 'vserver01_root':
    exportpolicy => 'nfs_exports',
  }
  netapp_volume { 'nfsvol':
    ensure       => present,
    aggregate    => 'aggr1',
    initsize     => '200g',
    exportpolicy => 'nfs_exports',
    junctionpath => '/nfsvol',
  }
  netapp_qtree { 'qtree1':
    ensure => present,
    volume => 'nfsvol',
  }
  netapp_nfs { 'vserver01':
    ensure => present,
    state  => 'on',
    v3     => 'disabled',
    v40    => 'enabled',
  }
}
~~~

If the device configuration are both in `$confdir/device.conf`, they can now be
configured by running `puppet device --verbose --user=root`.

If the device configurations are is separate files, you can use the following
command to run puppet against a single device at a time:

~~~
puppet device --verbose --user=root --deviceconfig /etc/puppet/device/ontap01.example.com.conf
~~~

<!--
### NetApp operations
As part of this module, there is a define called 'netapp::vqe', which can be used to create a volume, add a qtree and create an NFS export.

An example of this is:

~~~
netapp::vqe { 'volume_name':
  ensure     => present,
  size       => '1t',
  aggr       => 'aggr2',
  spaceres   => 'volume',
  snapresv   => 20,
  autosize   => 'grow',
  persistent => true
}
~~~

This will create a NetApp volume called `v_volume_name` with a qtree called `q_volume_name`.
The volume will have an initial size of 1 Terabyte in Aggregate aggr2.
The space reservation mode will be set to volume, and snapshot space reserve will be set to 20%.
The volume will be able to auto increment, and the NFS export will be persistent.

You can also use any of the types individually, or create new defined types as required.
-->\

### Classes and Defined Types

None as of this first release. Common operations may be encapsulated in defined resource types.

### Types and Providers

[`netapp_aggregate`](#type-netapp_aggregate)
[`netapp_cluster_id`](#type-netapp_cluster_id)
[`netapp_cluster_peer`](#type-netapp_cluster_peer)
[`netapp_export_policy`](#type-netapp_export_policy)
[`netapp_export_rule`](#type-netapp_export_rule)
[`netapp_group`](#type-netapp_group)
[`netapp_ldap_client`](#type-netapp_ldap_client)
[`netapp_license`](#type-netapp_license)
[`netapp_lif`](#type-netapp_lif)
[`netapp_lun`](#type-netapp_lun)
[`netapp_lun_map`](#type-netapp_lun_map)
[`netapp_nfs`](#type-netapp_nfs)
[`netapp_notify`](#type-netapp_notify)
[`netapp_qtree`](#type-netapp_qtree)
[`netapp_quota`](#type-netapp_quota)
[`netapp_role`](#type-netapp_role)
[`netapp_security_login`](#type-netapp_security_login)
[`netapp_security_login_role`](#type-netapp_security_login_role)
[`netapp_snapmirror`](#type-netapp_snapmirror)
[`netapp_snapmirror_schedule`](#type-netapp_snapmirror_schedule)
[`netapp_user`](#type-netapp_user)
[`netapp_volume`](#type-netapp_volume)
[`netapp_vserver`](#type-netapp_vserver)
[`netapp_vserver_option`](#type-netapp_vserver_option)
[`netapp_vserver_sis_config`](#type-netapp_vserver_sis_config)

### Type: netapp_aggregate
Manage Netapp Aggregate creation, modification and deletion. [Family: cluster]

#### Parameters
All parameters, except where otherwise noted, are optional.

##### `blocktype`

The indirect block format for the aggregate. Default value: '64_bit'. 

Valid values are `64_bit`, `32_bit`.

##### `checksumstyle`

Aggregate checksum style. Default value: 'block'.

Valid values are `advanced_zoned`, `block`.

##### `diskcount`

Number of disks to place in the aggregate, including parity disks.

##### `disksize`

Disk size with unit to assign to aggregate.

##### `disktype`

Disk types to use with aggregate. Only required when multiple disk types are connected.

Valid values are `ATA`, `BSAS`, `EATA`, `FCAL`, `FSAS`, `LUN`, `MSATA`, `SAS`, `SATA`, `SCSI`, `SSD`, `XATA`, `XSAS`.

##### `ensure`

The basic state that the resource should be in.

Valid values are `present`, `absent`.

##### `groupselectionmode`

How should Data ONTAP add disks to raidgroups.

Valid values are `last`, `one`, `new`, `all`.

##### `ismirrored`

Should the aggregate be mirrored (have two plexes). Defaults to false.

Valid values are `true`, `false`.

##### `name`

The aggregate name

##### `nodes`

Target nodes to create aggregate. May be an array.

##### `raidsize`

Maximum number of disks in each RAID group in aggregate.

Valid values are between 2 and 28

##### `raidtype`

Raid type to use in the new aggregate. Default: raid4.

Valid values are `raid4`, `raid_dp`.

##### `state`

The aggregate state. Default value: 'online'.

Valid values are `online`, `offline`.

##### `striping`

Should the new aggregate be striped? Default: not_striped.

Valid values are `striped`, `not_striped`.

### Type: netapp_cluster_id
Manage Netapp Cluster ID. [Family: cluster]

#### Parameters
##### `contact`
The cluster contact

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `location`
The cluster location

##### `name`
The cluster name

### Type: netapp_cluster_peer
Manage Netapp Cluster Peering. [Family: cluster]

#### Parameters
##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `name`
The cluster peer name. Must match the remote cluster name.

##### `password`
Cluster peer password.

##### `peeraddresses`
Cluster peer address array

##### `timeout`
Cluster operation timeout. Must be between 25 and 180. Defaults to: 25.

##### `username`
Cluster peer username.

### Type: netapp_export_policy

Manage Netapp CMode Export Policy creation and deletion. [Family: vserver]

#### Parameters

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `name`

The export policy name.

### Type: netapp_export_rule

Manage Netapp CMode Export rule creation, modification and deletion. [Family: vserver]

#### Parameters

##### `allowdevenabled`

Should the NFS server allow creation of devices. Defaults to true.

Valid values are `true`, `false`.

##### `allowsetuid`

Should the NFS server allow setuid. Defaults to true.

Valid values are `true`, `false`.

##### `anonuid`

User name or ID to map anonymous users to. Defaults to 65534.

##### `clientmatch`

*Required*. Client match specification for the export rule. May take an fqdn, IP address, IP hyphenated range, or CIDR notation. 

##### `ensure`

The basic state that the resource should be in.

Valid values are `present`, `absent`.

##### `exportchownmode`

Change ownership mode. Defaults to 'restricted'.

Valid values are `restricted`, `unrestricted`.

##### `name`
The export policy name and index. Must take the form of `policy_name:rule_number` where the rule number is an integer and the policy name is an existing export policy.

##### `ntfsunixsecops`

Ignore/Fail Unix security operations on NTFS volumes. Defaults to 'fail'.

Valid values are `ignore`, `fail`.

##### `protocol`

Client access protocol. Defaults to 'any'.

Valid values are `any`, `nfs2`, `nfs3`, `nfs`, `cifs`, `nfs4`, `flexcache`.

##### `rorule`

Property to configure read only rules. Defaults to 'any'.

Valid values are `any`, `none`, `never`, `never`, `krb5`, `ntlm`, `sys`, `spinauth`.

##### `rwrule`

Property to configure read write rules. Defaults to 'any'.

Valid values are `any`, `none`, `never`, `never`, `krb5`, `ntlm`, `sys`, `spinauth`.

##### `superusersecurity`

Superuser security flavor. Defaults to 'any'.

Valid values are `any`, `none`, `never`, `never`, `krb5`, `ntlm`, `sys`, `spinauth`.

### Type: netapp_group
Manage Netapp Group creation, modification and deletion.

#### Parameters
##### `comment`
Group comment

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `groupname`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

The group name.

##### `roles`
List of roles for this group. Comma separate multiple values.

### Type: netapp_igroup
Manage Netapp initiator groups. [Family: vserver]

#### Parameters
##### `name`
**Namevar:** If omitted, this parameter's value defaults to the resource's title.

Initiator group name.

##### `force`
Forcibly remove the initiator even if there are existing LUNs mapped to this initiator group. Best practice is to attempt to unmap all the luns associated with a group before removing the initiator. Default to false

##### `group_type`
Initiator group type.

Valid values are `fcp`, `iscsi`, `mixed`.

##### `members`
An array of initiator WWPNs or aliases to be members of the initiator group.

##### `os_type`
OS type of the initiators within the group. The os type applies to all initiators within the group and governs the finer details of SCSI protocol interaction with these initiators. Required.

Valid values are `solaris`, `windows`, `hpux`, `aix`, `linux`, `netware`, `vmware`, `openvms`, `xen`, `hyper_v`.

##### `portset`
The name of the portset to which the igroup should be bound. A value of `false` will unbind the portset.

Valid values are a string or `false`

### Type: netapp_iscsi
Manage Netapp ISCSI service. There may only ever be one of these declared per VServer. [Family: vserver]

#### Parameters
##### `svm`
**Namevar:** If omitted, this parameter's value defaults to the resource's title.

ISCSI service SVM.

##### `target_alias`
ISCSI WWPN alias. May be any string that is a valid ISCSI target WWPN.

##### `state`
ISCSI service state.

Valid values are `on`, `off`.

### Type: netapp_iscsi_security
Manage Netapp ISCSI initiator (client) authentication. [Family: vserver]

#### Parameters
##### `initiator`
**Namevar:** If omitted, this parameter's value defaults to the resource's title.

ISCSI initiator name.
##### `auth_type`
ISCSI initiator authentication type.

Valid values are `chap`, `none`, `deny`.

##### `radius`
ISCSI radius CHAP setting.

Valid values are `true`, `false`.

##### `username`
ISCSI initiator inbound CHAP username.

##### `password`
ISCSI initiator inbound CHAP password.

Valid values are 12-16 hexidecimal digits.

##### `outbound_username`
ISCSI initiator outbound CHAP username.

##### `outbound_password`
ISCSI initiator outbound CHAP password.

Valid values are 12-16 hexidecimal digits.

### Type: netapp_license
Manage Netapp Licenses. Only supported by ONTAP 8.2 and newer. [Family: cluster]
This allows the removal or addition of a license. eg
netapp_license { 'snaprestore' :
    ensure => present,
    codes  => "secret license code",
  }

#### Parameters
##### `package`
(**Namevar:**)
Package Possible values:
base - Cluster Base License,
nfs - NFS License,
cifs - CIFS License,
iscsi - iSCSI License,
fcp - FCP License,
snaprestore - SnapRestore License,
snapmirror - SnapMirror License,
flexclone - FlexClone License,
snapvault - SnapVault License,
snaplock - SnapLock License,
snapmanagersuite - SnapManagerSuite License,
snapprotectapps - SnapProtectApp License,
v_storageattach - Virtual Attached Storage License

##### `codes`
The license code to be added

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

### Type: netapp_ldap_client
Manage Netapp LDAP client configuration for the cluster. [Family: vserver]

#### Parameters
##### `name`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

The name of the LDAP client configuration.

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `ad_domain`
The Active Directory Domain Name for this LDAP configuration. The option is ONLY applicable for configurations using Active Directory LDAP servers.The Active Directory Domain Name for this LDAP configuration. The option is ONLY applicable for configurations using Active Directory LDAP servers.

##### `allow_ssl`
Allows the use of SSL for the TLS Handshake Protocol over the LDAP connections. The default value is false.

##### `base_dn`
Indicates the starting point for searches within the LDAP directory tree. If omitted, searches will start at the root of the directory tree.

##### `base_scope`
This indicates the scope for LDAP search. If omitted, this parameter defaults to 'subtree'. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates

##### `bind_as_cifs_server`
If set, the cluster will use the CIFS server's credentials to bind to the LDAP server. If omitted, this parameter defaults to 'true' if the configuration uses Active Directory LDAP and defaults to 'false' otherwise.

##### `bind_dn`
The Bind Distinguished Name (DN) is the LDAP identity used during the authentication process by the clients. This is required if the LDAP server does not support anonymous binds. This field is not used if 'bind-as-cfs-server' is set to 'true'. Example : cn=username,cn=Users,dc=example,dc=com

##### `bind_password`
The password to be used with the bind-dn.

##### `group_dn`
The Group Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for group lookups. If not specified, group lookups will start at the base-dn.

##### `group_scope`
This indicates the scope for LDAP search when doing group lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates

##### `is_netgroup_byhost_enabled`
This indicates whether netgroup.byhost map should be queried for lookups

##### `min_bind_level`
The minimum authentication level that can be used to authenticate with the LDAP server. If omitted, this parameter defaults to 'sasl'. Possible values:
anonymous - Anonymous bind,
simple - Simple bind,
sasl - Simple Authentication and Security Layer (SASL) bind

##### `netgroup_byhost_dn`
The Netgroup Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for netgroup byhost lookups. If not specified, netgroup byhost lookups will start at the base-dn.

##### `netgroup_byhost_scope`
This indicates the scope for LDAP search when doing netgroup byhost lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates

##### `netgroup_dn`
The Netgroup Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for netgroup lookups. If not specified, netgroup lookups will start at the base-dn.

##### `netgroup_scope`
This indicates the scope for LDAP search when doing netgroup lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates

##### `preffered_ad_servers`
Preferred Active Directory (AD) Domain controllers to use for this configuration. This option is ONLY applicable for configurations using Active Directory LDAP servers

##### `query_timeout`
Maximum time in seconds to wait for a query response from the LDAP server. The default for this parameter is 3 seconds.

##### `schema`
LDAP schema to use for this configuration.

##### `servers`
List of LDAP Server IP addresses to use for this configuration. The option is NOT applicable for configurations using Active Directory LDAP servers.

##### `tcp_port`
The TCP port on the LDAP server to use for this configuration. If omitted, this parameter defaults to 389.

##### `use_start_tls`
This indicates if start_tls will be used over LDAP connections.

##### `user_dn`
The User Distinguished Name (DN), if specified, is used as the starting point in the LDAP directory tree for user lookups. If this parameter is omitted, user lookups will start at the base-dn.

##### `user_scope`
This indicates the scope for LDAP search when doing user lookups. Possible values:
base - Searches only the base directory entry,
onelevel - Searches the immediate subordinates of the base directory entry,
subtree - Searches the base directory entry and all its subordinates

### Type: netapp_lif

Manage Netapp Logical Inteface (LIF) creation, modification and deletion. [Family: cluster]

#### Parameters

##### `address`

LIF IP address. *Required*

##### `administrativestatus`

LIF administratative status. Defaults to: 'up'.

Valid values are `up`, `down`.

##### `comment`

LIF comment.

##### `dataprotocols`

LIF data protocols.

Valid values are `nfs`, `cifs`, `iscsi`, `fcp`, `fcache`, `none`.

##### `dnsdomainname`

LIF dns domain name.

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `failovergroup`

LIF failover group name.

##### `failoverpolicy`

LIF failover policy. Defaults to: 'nextavail'.

Valid values are `nextavail`, `priority`, `disabled`.

##### `firewallpolicy`

LIF firewall policy. Default is based on the port role.

Valid values are `mgmt`, `cluster`, `intercluster`, `data`.

##### `homenode`

*Required*. LIF home node.

##### `homeport`

*Required*. LIF home port.

##### `interfacename`

**Namevar:** If omitted, this parameter's value defaults to the resource's title. LIF name.

##### `isautorevert`

Should the LIF revert to its home node. Defaults to: `false`.

Valid values are `true`, `false`.

##### `netmask`

LIF netmask. *Required* if `netmasklength` is not specified.

##### `netmasklength`

LIF netmask length. *Required* if `netmask` is not specified.

##### `role`

LIF Role. Defaults to: 'data'.

Valid values are `undef`, `cluster`, `data`, `node_mgmt`, `intercluster`, `cluster_mgmt`.

##### `routinggroupname`

LIF Routing group. Valid format is {dcn}{ip address}/{subnet}.

##### `usefailovergroup`

Whether the failover group should be automatically created. Defaults to: 'disabled'.

Valid values are `disabled`, `enabled`, `system_defined`.

##### `vserver`

*Required*. LIF Vserver name.

### Type: netapp_lun
Manage Netap Lun creation, modification and deletion. [Family: vserver]

#### Parameters
##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `lunclass`
Lun class. Default value = 'regular'. Possible values: 'regular', 'protectedendpoint', 'vvol'.

Valid values are `regular`, `protectedendpoint`, `vvol`.

##### `ostype`
Lun OS Type. Defaults to 'image'. Possible values: 'image', 'aix', 'hpux', 'hyper_v', 'linux', 'netware', 'openvms', 'solaris', 'solaris_efi', 'vmware', 'windows', 'windows_2008', 'windows_gpt'

Valid values are `image`, `aix`, `hpux`, `hyper_v`, `linux`, `netware`, `openvms`, `solaris`, `solaris_efi`, `vmware`, `windows`, `windows_2008`, `windows_gpt`.

##### `path`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

Lun path

##### `prefixsize`
Lun prefix stream size in bytes. Default value is based on ostype. Not required for 'image' ostype. Must be a multiple of 512 bytes.

##### `qospolicygroup`
QOS Policy group

##### `size`
Lun size. Can either be specified in bytes, or specify one of the following size units: [mgt].

##### `spaceresenabled`
Enable Lun space reservation? Defaults to true.

Valid values are `true`, `false`.

##### `force`
whether or not to force a resize, when shrinking the lun.

Valid values are `true`, `false`.


##### `state`
Lun state. Default value: 'online'. Possible values: 'online', 'offline'.

Valid values are `online`, `offline`.

### Type: netapp_lun_map
Manage Netap Lun map creation and deletion. [Family: vserver]

#### Parameters
##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `ensure`
Initiator group to map to.

##### `lunmap`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

Lun map - Composite key of format {path}:{lun-id}.

### Type: netapp_nfs

Manage NetApp NFS service. [Family: vserver]

#### Parameters

##### `vserver`

**Namevar:** If omitted, this parameter's value defaults to the resource's title. NFS service SVM. This resource can only be applied to vservers, so the title is redundant.

##### `state`

NFS Service State

Valid values are `on`, `off`.

##### `v3`

Control NFS v3 access

Valid values are `enabled`, `disabled`.

##### `v40`

Control NFS v4.0 access

Valid values are `enabled`, `disabled`.

##### `v41`

Control NFS v4.1 access

Valid values are `enabled`, `disabled`.

### Type: netapp_notify
Sends an arbitrary message to the agent run-time log.

#### Parameters
##### `message`
The message to be sent to the log.

##### `message`
An arbitrary tag for your own reference; the name of the message.

##### `message`
Whether to show the full object path. Defaults to false.

Valid values are `true`, `false`.

### Type: netapp_qtree

Manage Netapp Qtree creation, modification and deletion. [Family: vserver]

#### Parameters

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `exportpolicy`

The export policy with which the qtree is associated. (Note: Not yet implemented)

##### `name`

The qtree name.

##### `volume`

*Required.*. The volume to create the qtree against. 

### Type: netapp_quota
Manage NetApp quota entries.  Please note that NetApp identifies
a quota entry uniquely by the type, target, volume, and qtree. This type
on the other hand has to uniquely identify a quota entry only by its
target.  This means that you cannot manage two quota entries for the
same user (username = quota-target) but for different trees. As a result
this type is best at managing tree quotas

Example:

Limit qtree1 on vol1 to 10G

~~~puppet
netapp_quota { '/vol/vol1/qtree1':
  ensure    => present,
  type      => 'tree',
  volume    => 'vol1',
  disklimit => '10G',
}
~~~

Limit user bob to consume 2G on qtree1. Note that you cannot
define multiple quotas for user bob:

~~~puppet
netapp_quota { 'bob':
  ensure    => present,
  type      => 'user',
  qtree     => 'qtree1',
  volume    => 'vol1',
  disklimit => '2048M',
}
~~~

Make sure the following restrictions apply in your
environment before using this type:
- every quota target has to be unique
- quota entries must not contain any special characters that would
  require quotation

#### Parameters
##### `disklimit`
The amount of space that the target can consume, e.g. `100M` or `2G`. You can also specify absent to make sure there is no limit.

Valid values are `absent`. Values can match `/^[0-9]+[KMGT]$/i`.

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `filelimit`
The number of files that the target can have. You can also specify absent to make sure there is no limit.

Valid values are `absent`. Values can match `/^[0-9]+[KMGT]?$/i`.

##### `name`
The name of the quota target.  Depending on the quota type this can be a pathname (e.g. `/vol/vol1/qtree1`), a username, or a group

##### `qtree`
The qtree that the quota resides on. This is only relevant for `user` and `group` quotas

##### `softdisklimit`
The amount of space the target has to consume before a message is logged. You can also specify absent to make sure there is no limit.

Valid values are `absent`. Values can match `/^[0-9]+[KMGT]$/i`.

##### `softfilelimit`
The number of files the target has to own before a message is logged. You can also specify absent to make sure there is no limit

Valid values are `absent`. Values can match `/^[0-9]+[KMGT]?$/i`.

##### `threshold`
The amount of disk space the target has to consume before a message is logged. Set to absent to make sure the treshold is unlimited

Valid values are `absent`. Values can match `/^[0-9]+[KMGT]$/i`.

##### `type`
The type of the quota. You can define `tree`, `user` or `group` here

Valid values are `tree`, `user`, `group`.

##### `volume`
The name of the volume the quota resides on

Values can match `/^\w+$/`.

### Type: netapp_role
Manage Netapp Role creation, modification and deletion. [Family: cluster]

#### Parameters
##### `capabilities`
List of capabilities for this role. Comma separate multiple values.

##### `comment`
Role comment

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `rolename`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

The role name.

### Type: netapp_sis_policy

Manage Netapp sis policies. [Family: vserver]

#### Parameters

##### `type`

The type of policy.

Valid values are `threshold`, `scheduled`.

##### `job_schedule`

Job schedule name. E.g., 'daily'.

##### `duration`

Job duration in hours.

##### `enabled`

Manage whether the sis policy is enabled.

Valid values are `true`, `false`, `yes`, `no`, `enabled`, `disabled`

##### `comment`

Comment for the policy.

##### `qos_policy`

QoS policy name. E.g., 'best\_effort'

##### `changelog_threshold_percent`

Percentage at which the changelog will be processed for a threshold type of policy, tested once each hour

### Type: netapp_security_login
A user account associated with the specified application and authentication method. A new user account can be created with user name as the Active Directory group name. This user account gives access to users belonging to the specified Active Directory group. [Family: cluster]

#### Parameters
##### `comment`
Comments for the user account. The length of comment should be less than or equal to 128 charaters.

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `is_locked`
Whether the login is locked'.

The valid values for are 'true' or 'false'.

##### `name`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.) A composite key made up from `application:authentication_method:username:vserver` eg `ssh:password:vsadmin:vserver01`

##### `password`
Password for the user account. This is ignored for creating snmp users. This is required for creating non-snmp users.

##### `role_name`
*Required.* The default value is 'admin' for Admin vserver and 'vsadmin' for data vserver. This field is required.

### Type: netapp_security_login_role
Manages a login role. [Family: cluster]

#### Parameters

##### `access_level`
Access level for the role. Possible values: 'none', 'readonly', 'all'. The default value is 'all'.

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `name`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.) A composite key made up from `command_directory_name:role_name:vserver` eg `ssh:password:vsadmin:vserver01`

##### `role_query`
A query for the role. The query must apply to the specified command or directory name. Example: The command is 'volume show' and the query is '-volume vol1'. The query is applied to the command resulting in populating only the volumes with name vol1.

### Type: netapp_snapmirror
Manage Netapp Snapmirror creation, modification and deletion. [Family: cluster, vserver]

#### Parameters
##### `destination_location`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

The destination location.

##### `destination_snapshot`
The destination snapshot.

##### `ensure`
Netapp Snapmirror resource state. Valid values are: present, absent.

Valid values are `present`, `absent`.

##### `max_transfer_rate`
The max transfer rate, in KB/s. Defaults to unlimited.

##### `relationship_type`
Specifies the type of the SnapMirror relationship. An extended data protection relationship with a policy of type vault is equivalent to a 'vault' relationship. On Data ONTAP 8.3.1 or later, in the case of a Vserver SnapMirror relationship the type of the relationship is always data_protection. Possible values: data_protection , load_sharing , vault , restore , transition_data_protection , extended_data_protection

##### `source_location`
The source location.

##### `source_snapshot`
The source snapshot name

### netapp_snapmirror_schedule
Manage Netapp Snapmirror schedule creation, modification and deletion.

#### Parameters
##### `connection_mode`
The connection mode to use between source and destination.

Valid values are `inet`, `inet6`.

##### `days_of_month`
The days of month for schedule to be set.  Can be single value between 1 and 31, comma seperated list (1,7,14), range (2-10), range with divider (1-30/7), * to match all, or - to match none.

##### `days_of_week`
The days of week for schedule to be set. Can be single value between 0 and 6, inclusive, with 0 being Sunday, or must be name of the day (e.g. Tuesday), comma sepeated list (1,3,5), range (2-5), * to match all, or - to match none.

##### `destination_location`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

The destination location.

##### `ensure`
Netapp Snapmirror schedule resource state. Valid values are: present, absent.

Valid values are `present`, `absent`.

##### `hours`
The hour(s) in the day for schedule to be set.  Can be single value between 1 and 24, comma seperated list (1,7,14), range (2-10), range with divider (1-24/3), * to match all, or - to match none.

##### `max_transfer_rate`
The max transfer rate, in KB/s. Defaults to unlimited.

##### `minutes`
The minutes in the hour for schedule to be set.  Can be single value between 0 and 59, comma seperated list (1,7,14), range (2-10), range with divider (1-59/3), * to match all, or - to match none.

##### `restart`
The restart mode to use when transfer interrupted. Allowed values are: always, never and restart.

Valid values are `always`, `never`, `default`.

##### `source_location`
The source location.

### Type: netapp_user
Manage Netapp User creation, modification and deletion.

#### Parameters
##### `comment`
User comment

##### `ensure`
The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `fullname`
The user full name.

##### `groups`
List of groups for this user account. Comma separate multiple values.

##### `passmaxage`
Number of days that this user's password can be active before the user must change it. Default value is 2^31-1 days.

##### `passminage`
Number of days that this user's password must be active before the user can change it. Default value is 0.

##### `password`
The user password. Minimum length is 8 characters, must contain at-least one number.

##### `status`
Status of user account. Valid values are: enabled, disabled and expired. Cannot be modified via API.

Valid values are `enabled`, `disabled`, `expired`.

##### `username`
(**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

The user username.

### Type: netapp_volume

Manage Netapp Volume creation, modification and deletion. [Family: vserver]

#### Parameters

##### `aggregate`

*Required.*. The aggregate this volume should be created in. 

##### `autosize`

Whether volume autosize should be grow, grow/shrink, or off.

Valid values are `off`, `grow`, `grow_shrink`.

##### `ensure`

The basic state that the resource should be in.

Valid values are `present`, `absent`.

##### `exportpolicy`

The export policy with which the volume is associated.

##### `group_id`

The UNIX group ID for the volume.

##### `initsize`

The initial volume size. *Required.* Valid format is /[0-9]+[kmgt]/.

##### `junctionpath`

The fully-qualified pathname in the owning vserver's namespace at which a volume is mounted.

Valid values are absolute file paths or `false`.

##### `languagecode`

The language code this volume should use.

Valid values are `C`, `ar`, `cs`, `da`, `de`, `en`, `en_US`, `es`, `fi`, `fr`, `he`, `hr`, `hu`, `it`, `ja`, `ja_v1`, `ko`, `no`, `nl`, `pl`, `pt`, `ro`, `ru`, `sk`, `sl`, `sv`, `tr`, `zh`, `zh_TW`.

##### `name`

The volume name. Valid characters are a-z, 1-9 & underscore.

##### `options`

The volume options hash. Key/value pairs are configured via volume-option-info. Only valid in vserver context.

Example:

~~~puppet
netapp_volume { 'nfsvol':
  ensure       => 'present',
  autosize     => 'off',
  exportpolicy => 'nfs_exports',
  initsize     => '2g',
  junctionpath => '/nfsvol',
  state        => 'online',
  options      => {
    'actual_guarantee'          => 'volume',
    'convert_ucode'             => 'on',
    'create_ucode'              => 'on',
    'effective_guarantee'       => 'volume',
    'extent'                    => 'off',
    'fractional_reserve'        => '100',
    'fs_size_fixed'             => 'off',
    'guarantee'                 => 'volume',
    'ignore_inconsistent'       => 'off',
    'max_write_alloc_blocks'    => '0',
    'maxdirsize'                => '52346',
    'minra'                     => 'off',
    'no_atime_update'           => 'off',
    'no_i2p'                    => 'off',
    'nosnap'                    => 'off',
    'nosnapdir'                 => 'off',
    'nvfail'                    => 'off',
    'read_realloc'              => 'off',
    'root'                      => 'false',
    'schedsnapname'             => 'create_time',
    'snapmirrored'              => 'off',
    'snapshot_clone_dependency' => 'off',
    'try_first'                 => 'volu me_grow',
  },
}
  snapreserve  => '5',
  snapschedule => {'days' => '2', 'hours' => '6', 'minutes' => '0', 'weeks' => '1', 'which-hours' => '0:05, 1:05, 2:05, 3:05, 4:05, 5:05, 6:05, 7:05, 8:05, 9:05, 10:05, 11:05, 12:05, 13:05, 14:05, 15:05,
      16:05, 17:05, 18:05, 19:05, 20:05, 21:05, 22:05, 23:05', 'which-minutes' => ''},
~~~

##### `snapreserve`

The percentage of space to reserve for snapshots.

##### `snapschedule`

The volume snapshot schedule, in a hash format. Valid keys are: 'minutes', 'hours', 'days', 'weeks', 'which-hours', 'which-minutes'.

Example:

~~~puppet
netapp_volume { 'nfsvol':
  ensure       => 'present',
  autosize     => 'off',
  exportpolicy => 'nfs_exports',
  initsize     => '2g',
  junctionpath => '/nfsvol',
  state        => 'online',
  snapreserve  => '5',
  snapschedule => {
    'days'          => '2',
    'hours'         => '6',
    'minutes'       => '0',
    'weeks'         => '1',
    'which-hours'   => '0:05, 12:05',
    'which-minutes' => '',
  },
}
~~~

##### `spaceres`

The space reservation mode.

Valid values are `none`, `file`, `volume`.

##### `state`

The volume state.

Valid values are `online`, `offline`, `restricted`.

##### `unix_permissions`

Unix permission bits in octal string format.It's similar to Unix style permission bits: In Data ONTAP 7-mode, the default setting of '0755' gives read/write/execute permissions to owner and read/execute to group and other users. In Data ONTAP Cluster-Mode, for security style 'mixed' or 'unix', the default setting of '0755' gives read/write/execute permissions to owner and read/execute permissions to group and other users. For security style 'ntfs', the default setting of '0000' gives no permissions to owner, group and other users. It consists of 4 octal digits derived by adding up bits 4, 2 and 1. Omitted digits are assumed to be zeros. First digit selects the set user ID(4), set group ID (2) and sticky (1) attributes. The second digit selects permission for the owner of the file: read (4), write (2) and execute (1); the third selects permissions for other users in the same group; the fourth for other users not in the group.

##### `user_id`

The UNIX user ID for the volume.

##### `volume_type`

The type of the volume to be created. Possible values:
rw - read-write volume (default setting),
ls - load-sharing volume,
dp - data-protection volume,
dc - data-cache volume (FlexCache)

### Type: netapp_vserver

Manage Netapp Vserver creation, modification and deletion. [Family: cluster, vserver]

#### Parameters

##### `aggregatelist`

Vserver aggregate list. May be an array.

##### `allowedprotos`

Vserver allowed protocols.

Valid values are `nfs`, `cifs`, `fcp`, `iscsi`, `ndmpd`.

##### `comment`

Vserver comment.

##### `ipspace`

IPspace name.

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `language`

Vserver language. Defaults to `c.UTF-8`

Valid values are `c`, `c.UTF-8`, `ar`, `cs`, `da`, `de`, `en`, `en_us`, `es`, `fi`, `fr`, `he`, `hr`, `hu`, `it`, `ja`, `ja_v1`, `ja_jp.pck`, `ja_jp.932`, `ja_jp.pck_v2`, `ko`, `no`, `nl`, `pl`, `pt`, `ro`, `ru`, `sk`, `sl`, `sv`, `tr`, `zh`, `zh.gbk`, `zh_tw`.

##### `maxvolumes`

Vserver maximum allowed volumes.

##### `name`

The vserver name

##### `namemappingswitch`

Vserver name mapping switch. Defaults to 'file'.

Valid values are `file`, `ldap`.

##### `nameserverswitch`

Vserver name server switch.

Valid values are `file`, `ldap`, `nis`.

##### `quotapolicy`

Vserver quota policy.

##### `rootvol`

*Required.* The vserver root volume.

##### `rootvolaggr`

*Required.* Vserver root volume aggregate.

##### `rootvolsecstyle`

*Required.* Vserver root volume security style.

Valid values are `unix`, `ntfs`, `mixed`, `unified`.

##### `snapshotpolicy`

Vserver snapshot policy.

##### `state`

The vserver state.

Valid values are `stopped`, `running`.

### Type: netapp_vserver_option

Manage Netapp Vserver option modification. [Family: cluster, vserver]

#### Parameters

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `name`

The vserver option name.

##### `value`

The vserver option value.

### Type: netapp_sis_config

Manage Netapp Vserver sis config modification. [Family: vserver]

#### Parameters

##### `compression`

Enable compression on the sis volume.

Valid options: `true`, `false`.

##### `enabled`

Enable sis on a volume.

Valid options: `true`, `false`.

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `idd`

Enables file level incompressible data detection and quick check incompressible data detection for large files.

Valid options: `true`, `false`.

##### `inline_compression`

Enable inline compression on the sis volume.

Valid options: `true`, `false`.

##### `path`

(**Namevar:** If omitted, this parameter's value defaults to the resource's title.) The full path of the sis volume, `/vol/<vol_name>`.

##### `policy`

The sis policy name to be attached to the volume.

##### `quick_check_fsize`

Quick check file size for Incompressible Data Detection. Accepts integers

Values can match `/^\d+$/`.

##### `sis_schedule`

The schedule string for the sis operation.

Accepts the following formats:

* `day_list[@hour_list]`
* `hour_list[@day_list]`
* `-`
* `auto`
* `manual`

## TODO
The following items are yet to be implemented:

 * Data Fabric Manager support
 * Support adding/deleting/modifying cifs shares
 * LDAP and/or AD configuration
 * QA remaining resources

## Development

The following section applies to developers of this module only.

### Testing

You will need to install the NetApp Manageability SDK Ruby libraries for most of the tests to work.

How to obtain these files is detailed in the NetApp Manageability SDK section above.
