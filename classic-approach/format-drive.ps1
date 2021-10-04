function handler($context, $inputs) {
    
    $vmname = $inputs.resourceNames[0]

    # Build Credentials, stored as Action Constants
    $user = $inputs["vcUser"]
    $pass = $context.getSecret($inputs["vcPassword"])
    $secPass = ConvertTo-SecureString $pass -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($user, $secPass)
    
    $osUser = $inputs["osUser"]
    $osPass = $context.getSecret($inputs["osPassword"])
    $osSecPass = ConvertTo-SecureString $osPass -AsPlainText -Force
    $osCred = New-Object System.Management.Automation.PSCredential ($osUser, $osSecPass)
    write-host "oscred"

    # Ignore cert errors for this powerCLI session
    Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false

    # Connect to the vcenter
    $vc = connect-viserver -server "vsphere.local" -credential $cred

    # Get the vm object 
    $vm = get-vm $vmname -server $vc

	  # Create a script that can be run on the vm to initialize/format the disk
    $script =  '$disk = get-disk | ? {$_.PartitionStyle -eq "Raw"} | select -first 1;'
    $script += 'initialize-disk -inputobject $disk;'
    $script += '$p = new-partition $disk.number -UseMaximumSize -AssignDriveLetter:$false;'
    $script += '$p | Format-Volume -FileSystem NTFS -Confirm:$false;' 
    $script += '$p | Set-Partition -NewDriveLetter "E"'
    
	  # Invoke the script on the vm
    $result = invoke-vmscript -vm $vm -ScriptText $script -GuestCredential $osCred
}
