#  == Define: netapp:nfs
#
#  Utility for provisoning NFS Share
#
# ===Parameters:
#
#  [*size*]
#   The size of the NFS Share to be created
#
#  [*client*]
#   The CIDR of the clients that would be accessing the share
#
#  [*path*]
#    The export path to access the share
# 
#  ==Sample usage:
#
#  Make sure there is an SVM "SVM3" exists which allows NFS data protocol 
#
#  node "svm3.localdomain" {
#   netapp::nfs {"TestVol":
#     size => "1g",
#     client => "172.0.0.0/8",
#     path => '/svm3testvol1'
#   }
#  }

  define netapp::nfs  (
    $size,
    $client,
    $path,
    $svm = "svm3",
    $svm_root = "rootdir",
    $aggr = "aggr01_node02",
    $exp_policy = "exp_svm3",
    $root_policy = "default",
    $root_policy_rule = "1",
    $root_policy_match = "0.0.0.0/0",
    $rule = "1",
    $ensure = "present",
    $spaceres = "volume",
    $spacereserve = "0",
    $protocol = ['nfs'],
    $rorule = ['sys','none'],
    $rwrule = ['sys', 'none'],
    $superusersecurity = "none",
    $state = "on"
   ) {

   netapp_export_policy {"${exp_policy}_${name}":
     ensure => $ensure
   }

   netapp_export_rule { "${exp_policy}_${name}:${rule}":
    ensure => $ensure,
    clientmatch => $client,
    protocol => $protocol,
    superusersecurity => $superusersecurity,
    rorule => $rorule,
    rwrule => $rwrule
   }->

   netapp_export_rule { "${root_policy}:${root_policy_rule}":
    ensure => $ensure,
    clientmatch => $root_policy_match,
    superusersecurity => $superusersecurity,
    rorule => $rorule,
    rwrule => $rwrule
   }->
   netapp_nfs { "${svm}":
    ensure => $ensure,
   }->

   netapp_volume { "${svm_root}":
    ensure => $ensure,
    exportpolicy => $root_policy,
   }->

   netapp_volume { "nfs_${name}":
    ensure => $ensure,
    aggregate => $aggr,
    initsize => $size,
    exportpolicy => "$exp_policy_$name",
    spaceres => $spaceres,
    junctionpath => $path,
    snapreserve => $snapreserve
   }

}


