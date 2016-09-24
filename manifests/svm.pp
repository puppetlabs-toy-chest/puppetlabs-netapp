# ==Define: netapp:svm
#
# Utility for creating a SVM and corresponding LIFs
#
# === Parameters:
#
# [*allowedprotos*]
#    The data protocols allowed by the SVM (E.g. ["iscsi","nfs"]
#
# [*address_mgmt*]
#    The IP address for management LIF
#
# [*mask_mgmt*]
#    The netmask of IP address for management LIF
# 
# [*address_data*]
#    The IP address for data LIF
#
# [*mask_data*]
#    The netmask of IP address for data LIF
# 
# [*homenode*] 
#    Node in the cluster acting as home node for the LIF
#  
# [*homeport*] 
#    Port of node in the cluster acting as home port for the LIF
#
# [*aggr*]
#     Name of the aggregate to be created
#
# [*aggrlist*]
#     aggregate list for the SVM
#
# === Sample usage
#   
#  Some variables need to be adjusted according to your environment.
#   
#     node "puppet-dev" {
#       netapp::svm {"svm_test":
#         allowedprotos => ["iscsi"],
#         address_mgmt => "172.21.11.132",
#         mask_mgmt => "255.255.255.0",
#         address_data => "172.21.11.133",
#         mask_data => "255.255.255.0",
#        }
#     }
#   
#   
  define netapp::svm  (
    $allowedprotos,
    $address_mgmt,
    $mask_mgmt,
    $address_data,
    $mask_data,
    $homenode = "puppet-dev-01",
    $homeport = "e0c",
    $aggr = "aggr01_node02",
    $aggrlist = ["aggr01_node02"],
    $firewallpolicy_mgmt = "mgmt",
    $firewallpolicy_data = "data",
    $svm_root = "rootdir",
    $rootvol = "rootdir",
    $role = "data",
    $status = "up",
    $failoverpolicy = "disabled"
   ) {


#Creates SVM 
   netapp_vserver {"${name}":
     ensure => $ensure,
     rootvol => $rootvol,
     rootvolaggr => $aggr,
     aggregatelist => $aggrlist,
     allowedprotos => $allowedprotos    
   }->


#Creates Management LIF
   netapp_lif  { "${name}_mgmt":
     ensure => $ensure,
     vserver => $name,
     role => $role,
     administrativestatus => $status,
     address => $address_mgmt,
     homenode => $homenode,
     homeport => $homeport,
     netmask => $mask_data,
     failoverpolicy => $failoverpolicy,
     firewallpolicy => $firewallpolicy_mgmt
   }->

#Creates Data LIF
   netapp_lif  { "${name}_data":
     ensure => $ensure,
     vserver => $name,
     role => $role,
     administrativestatus => $status,
     dataprotocols => $allowedprotos,
     address => $address_data,
     homenode => $homenode,
     homeport => $homeport,
     netmask => $mask_data,
     failoverpolicy => $failoverpolicy,
     firewallpolicy => $firewallpolicy_data
   }

}


