# == Define: netapp:iscsi
#
# Utility for provisioning a LUN 
# 
# 
# ===Parameters: 
# 
# [*size*]
#    The size of the LUN to be created
# 
# [*initiator*] 
#    An array of initiators
# 
# [*ostype*]
#    A host OS to which LUN is attached
# 
# [*lunid*]
#    LUN id of the mapping
# 
#  [*vol_name*]
#    The FlexVol for the LUN
# 
#  ==Sample usage:
#    
#  Make sure that there is a SVM  'vserver01' which allows iscsi data protocol
# 
#  node "vserver01.localdomain" {
#    netapp::iscsi {'host_lun':
#      size => "500mb",
#      lunid => "1",
#      initiator => ["iqn.1991-05.com.microsoft:cis-jump85.cis.netapp.com"],
#      ostype => "windows"
#    }
#  } 
# 
# 
  define netapp::iscsi  (
    $size,
    $lunid,
    $initiator,
    $ostype,
    $svm = "vserver01",
    $aggr = "aggr02_node01",
    $vol_name = 'vol1_iscsi',
    $vol_size = "1g",
    $grouptype = "iscsi",
    $ensure = "present",
    $spaceres = "volume",
    $spacereserve = "0",
    $spaceresenabled = "false",
    $state = "on",
    $igroup = "iscsi_igroup_$name"
   ) {



  netapp_volume { "${vol_name}":
    ensure => $ensure,
    aggregate => $aggr,
    initsize => $vol_size,
    spaceres => $spaceres,
    snapreserve => $snapreserve
  }->
  
  netapp_lun {"/vol/${vol_name}/${name}":
    ensure => $ensure,
    ostype => $ostype,
    size => $size,
    spaceresenabled => $spaceresenabled
  }->

  netapp_iscsi { "${svm}":
    ensure => $ensure,
  }->

  netapp_igroup { '${igroup}':
    ensure => $ensure,
    group_type => $grouptype,
    members => $initiator,
    os_type => $ostype,
    name => $igroup
 }->

 netapp_lun_map {"/vol/${vol_name}/${name}:${lunid}":
    ensure => $ensure,
    initiatorgroup =>  $igroup
    
  }
}

