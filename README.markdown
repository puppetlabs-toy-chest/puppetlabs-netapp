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
<!--  * [NetApp operations](#netapp-operations) -->
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

XXX Verify these
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
[`netapp_license`](#type-netapp_license)
[`netapp_lif`](#type-netapp_lif)
[`netapp_lun`](#type-netapp_lun)
[`netapp_lun_map`](#type-netapp_lun_map)
[`netapp_nfs`](#type-netapp_nfs)
[`netapp_notify`](#type-netapp_notify)
[`netapp_qtree`](#type-netapp_qtree)
[`netapp_quota`](#type-netapp_quota)
[`netapp_role`](#type-netapp_role)
[`netapp_snapmirror`](#type-netapp_snapmirror)
[`netapp_user`](#type-netapp_user)
[`netapp_volume`](#type-netapp_volume)
[`netapp_vserver`](#type-netapp_vserver)
[`netapp_vserver_option`](#type-netapp_vserver_option)
[`netapp_vserver_sis_config`](#type-netapp_vserver_sis_config)

### Type: netapp_aggregate
Manage Netapp Aggregate creation, modification and deletion.

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
Not yet reviewed.

### Type: netapp_cluster_peer
Not yet reviewed.

### Type: netapp_export_policy

Manage Netapp CMode Export Policy creation and deletion.

#### Parameters

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `name`

The export policy name.

### Type: netapp_export_rule

Manage Netapp CMode Export rule creation, modification and deletion.

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

The export policy. Composite name based on policy name and rule index. Must take the form of `policy_name:rule_number` where the rule number is an integer and the policy name is an existing export policy.

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
Not yet implemented.

### Type: netapp_igroup
Manage Netapp initiator groups

#### Parameters
##### name
**Namevar:** If omitted, this parameter's value defaults to the resource's title.

Initiator group name.

##### group_type
Initiator group type.

Valid values are `fcp`, `iscsi`, `mixed`.

##### members
An array of initiator WWPNs or aliases to be members of the initiator group.

##### os_type
OS type of the initiators within the group. The os type applies to all initiators within the group and governs the finer details of SCSI protocol interaction with these initiators. Required.

Valid values are `solaris`, `windows`, `hpux`, `aix`, `linux`, `netware`, `vmware`, `openvms`, `xen`, `hyper_v`.

##### portset
The name of the portset to which the igroup should be bound. A value of `false` will unbind the portset.

Valid values are a string or the boolean `false`
### Type: netapp_iscsi
Manage Netapp ISCSI service. There may only ever be one of these declared per VServer.

#### Parameters
##### svm
**Namevar:** If omitted, this parameter's value defaults to the resource's title.

ISCSI service SVM.

##### target_alias
ISCSI WWPN alias. May be any string that is a valid ISCSI target WWPN.

##### state
ISCSI service state.

Valid values are `on`, `off`.

### Type: netapp_iscsi_security
Manage Netapp ISCSI initiator (client) authentication.

#### Parameters
##### initiator
**Namevar:** If omitted, this parameter's value defaults to the resource's title.

ISCSI initiator name.
##### auth_type
ISCSI initiator authentication type.

Valid values are `chap`, `none`, `deny`.

##### radius
ISCSI radius CHAP setting.

Valid values are `true`, `false`.

##### username
ISCSI initiator inbound CHAP username.

##### password
ISCSI initiator inbound CHAP password.

Valid values are 12-16 hexidecimal digits.

##### outbound_username
ISCSI initiator outbound CHAP username.

##### outbound_password
ISCSI initiator outbound CHAP password.

Valid values are 12-16 hexidecimal digits.

### Type: netapp_license
Not yet reviewed.

### Type: netapp_lif

Manage Netapp Logical Inteface (LIF) creation, modification and deletion.

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

Valid values are `mgmt`, `cluster`, `intercluster`.

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
Not yet reviewed.

### Type: netapp_lun_map
Not yet reviewed.

### Type: netapp_nfs

Manage NetApp NFS service

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
Not yet reviewed.

### Type: netapp_qtree

Manage Netapp Qtree creation, modification and deletion.

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
Not yet reviewed.

### Type: netapp_role
Not yet reviewed.

### Type: netapp_sis_policy

Manage Netapp sis policies.

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

### Type: netapp_snapmirror
Not yet reviewed.

### Type: netapp_user
Not yet reviewed.

### Type: netapp_volume

Manage Netapp Volume creation, modification and deletion.

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

The volume options hash. XXX Needs more details

##### `snapreserve`

The percentage of space to reserve for snapshots.

##### `snapschedule`

The volume snapshot schedule, in a hash format. Valid keys are: 'minutes', 'hours', 'days', 'weeks', 'which-hours', 'which-minutes'. XXX Needs an example

##### `spaceres`

The space reservation mode.

Valid values are `none`, `file`, `volume`.

##### `state`

The volume state.

Valid values are `online`, `offline`, `restricted`.

### Type: netapp_vserver

Manage Netapp Vserver creation, modification and deletion.

#### Parameters

##### `aggregatelist`

Vserver aggregate list. May be an array.

##### `allowedprotos`

Vserver allowed protocols.

Valid values are `nfs`, `cifs`, `fcp`, `iscsi`, `ndmpd`.

##### `comment`

Vserver comment.

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

Manage Netapp Vserver option modification.

#### Parameters

##### `ensure`

The basic property that the resource should be in.

Valid values are `present`, `absent`.

##### `name`

The vserver option name.

##### `value`

The vserver option value.

### Type: netapp_sis_config

Manage Netapp Vserver sis config modification.

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
