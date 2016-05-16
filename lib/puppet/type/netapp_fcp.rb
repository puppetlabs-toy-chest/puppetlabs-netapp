Puppet::Type.newtype(:netapp_fcp) do
  @doc = "Manage NetApp FCP service. [Family: vserver]"

  apply_to_device

  ensurable

  newparam(:svm, :namevar => true) do
    desc "FCP service SVM"
  end 
 
  newproperty(:node_name)do
    desc "FCP WWNN for the FCP service"
  end

  newproperty(:state) do
    desc "FCP Service state"
    newvalues(:on, :off)
  end

  newparam(:force_node_name)do
    desc "True/False: Setting WWNN outside vendor's registered name space"
  end  

  newparam(:start)do
    desc "True/False: Start the FCP service after creation"
  end


end
